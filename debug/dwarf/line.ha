// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use debug::image;
use errors;
use format::elf;
use io;
use memio;

def MIN_LINE_VERSION: u16 = 2;
def MAX_LINE_VERSION: u16 = 3;

// Boolean flags for the line number state machine
export type line_flag = enum uint {
	NONE		= 0,
	IS_STMT		= 1 << 0,
	BASIC_BLOCK	= 1 << 1,
	END_SEQUENCE	= 1 << 2,
	PROLOGUE_END	= 1 << 3,
	EPILOGUE_BEGIN	= 1 << 4,
};

// Line number program state
export type line_state = struct {
	vm_loc: u64,
	addr: uintptr,
	op_index: uint,
	file: uint,
	line: uint,
	column: uint,
	flags: line_flag,
	isa: uint,
	discriminator: uint,
};

// A file with associated line numbers.
export type line_file = struct {
	name: str,
	dir: u64,
	mtime: u64,
	length: u64,
};

// Header information for a .debug_line program.
export type line_header = struct {
	min_instr_length: u8,
	max_ops_per_instr: u8,
	default_isstmt: bool,
	line_base: i8,
	line_range: u8,
	opcode_base: u8,
	opcode_lengths: []u8,
	dirs: []str,
	files: []line_file,
};

// Line number program
export type line_program = struct {
	mem: *memio::stream,
	rd: *table_reader,
	state: line_state,
	head: line_header,
};

// Initializes a new line number state machine to run the line number program at
// the specified offset in .debug_line.
//
// Use [[line_step]] to step the state machine, and pass the result to
// [[line_program_finish]] to free resources associated with the state machine
// when done using it.
export fn exec_line_program(
	image: *image::image,
	offs: u64,
) (line_program | void | io::error) = {
	const sec = match (image::section_byname(image, ".debug_line")) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return;
	};
	const memrd = alloc(image::section_reader(image, sec));
	io::seek(memrd, offs: io::off, io::whence::SET)?;
	const rd = alloc(new_table_reader(memrd, true)? as table_reader);

	// Read program header
	const ver = read_uhalf(rd)!;
	assert(ver >= MIN_LINE_VERSION && ver <= MAX_LINE_VERSION,
		"debug::dwarf: unsupported .debug_line version");

	let head = line_header { ... };
	const head_len = read_secword(rd)?;
	head.min_instr_length = read_ubyte(rd)?;
	head.max_ops_per_instr = 1; // Non-VLIW architectures only
	head.default_isstmt = read_ubyte(rd)? != 0;
	head.line_base = read_sbyte(rd)?;
	head.line_range = read_ubyte(rd)?;
	head.opcode_base = read_ubyte(rd)?;

	// Opcode lengths
	for (let i = 0u8; i < head.opcode_base - 1; i += 1) {
		const op = read_ubyte(rd)?;
		append(head.opcode_lengths, op);
	};

	// Directories
	for (true) {
		const dir = read_string(rd)?;
		if (len(dir) == 0) {
			break;
		};
		append(head.dirs, dir);
	};

	// Files
	for (true) {
		const name = read_string(rd)?;
		if (len(name) == 0) {
			break;
		};
		const dir = read_uleb128(rd)?;
		const mtime = read_uleb128(rd)?;
		const length = read_uleb128(rd)?;
		append(head.files, line_file {
			name = name,
			dir = dir,
			mtime = mtime,
			length = length,
		});
	};

	let prog = line_program {
		mem = memrd,
		rd = rd,
		state = line_state { ... },
		head = head,
	};
	line_prog_reset(&prog);
	return prog;
};

fn line_prog_reset(prog: *line_program) void = {
	const head = &prog.head;
	prog.state = line_state {
		vm_loc = 0,
		addr = 0,
		op_index = 0,
		file = 1,
		line = 1,
		column = 0,
		flags = if (head.default_isstmt) line_flag::IS_STMT else 0,
		isa = 0,
		discriminator = 0,
	};
};

// Frees resources associated with a [[line_program]].
export fn line_program_finish(prog: *line_program) void = {
	free(prog.mem);
	free(prog.rd);
	free(prog.head.opcode_lengths);
	free(prog.head.dirs);
	free(prog.head.files);
};

// Runs the line number state machine until the next COPY instruction.
export fn line_next(prog: *line_program) (line_state | io::EOF | io::error) = {
	for (true) {
		match (line_step(prog)?) {
		case let state: line_state =>
			return state;
		case io::EOF =>
			return io::EOF;
		case void => continue;
		};
	};
};

// Step the line number state machine. Returns the current line_state on a copy
// or end-of-sequence instruction, [[io::EOF]] at the end of the file, or void
// otherwise.
export fn line_step(
	prog: *line_program,
) (line_state | void | io::EOF | io::error) = {
	let state = &prog.state;
	if (read_iseof(prog.rd)) {
		return io::EOF;
	};
	state.vm_loc = read_tell(prog.rd);

	const opcode = read_ubyte(prog.rd)?;
	if (opcode == 0) {
		// Extended opcode
		const length = read_uleb128(prog.rd)?;
		const opcode = read_ubyte(prog.rd)?;
		switch (opcode) {
		case DW_LNE_end_sequence =>
			let copy = *state;
			line_prog_reset(prog);
			return copy;
		case DW_LNE_set_address =>
			state.addr = read_ulong(prog.rd)?: uintptr;
		case DW_LNE_define_file =>
			const name = read_string(prog.rd)?;
			const dir = read_uleb128(prog.rd)?;
			const mtime = read_uleb128(prog.rd)?;
			const length = read_uleb128(prog.rd)?;
			append(prog.head.files, line_file {
				name = name,
				dir = dir,
				mtime = mtime,
				length = length,
			});
			state.file = len(prog.head.files): uint;
		case DW_LNE_set_discriminator =>
			state.discriminator = read_uleb128(prog.rd)?: uint;
		case =>
			// Unknown opcode, skip
			read_slice(prog.rd, length - 1)?;
		};
	} else if (opcode < prog.head.opcode_base) {
		// Special opcode
		switch (opcode) {
		case DW_LNS_copy =>
			let copy = *state;
			state.discriminator = 0;
			state.flags &= ~(
				line_flag::BASIC_BLOCK |
				line_flag::PROLOGUE_END |
				line_flag::EPILOGUE_BEGIN);
			return copy;
		case DW_LNS_advance_pc =>
			const op_adv = read_uleb128(prog.rd)?;
			state.addr += (prog.head.min_instr_length * op_adv): uintptr;
		case DW_LNS_advance_line =>
			const line = state.line: i64;
			const offs = read_sleb128(prog.rd)?;
			line += offs;
			state.line = line: uint;
		case DW_LNS_set_file =>
			state.file = read_uleb128(prog.rd)?: uint;
		case DW_LNS_set_column =>
			state.column = read_uleb128(prog.rd)?: uint;
		case DW_LNS_negate_stmt =>
			state.flags ^= line_flag::IS_STMT;
		case DW_LNS_set_basic_block =>
			state.flags |= line_flag::BASIC_BLOCK;
		case DW_LNS_const_add_pc =>
			const opcode = 255 - prog.head.opcode_base;
			const op_adv = opcode / prog.head.line_range;
			state.addr += (prog.head.min_instr_length * op_adv): uintptr;
		case DW_LNS_fixed_advance_pc =>
			state.addr += read_uhalf(prog.rd)?: uintptr;
			state.op_index = 0;
		case DW_LNS_set_prologue_end =>
			state.flags |= line_flag::PROLOGUE_END;
		case DW_LNS_set_epilogue_begin =>
			state.flags |= line_flag::EPILOGUE_BEGIN;
		case DW_LNS_isa =>
			state.isa = read_uleb128(prog.rd)?: uint;
		case =>
			// Unknown opcode, skip
			const length = prog.head.opcode_lengths[opcode - 1];
			for (length != 0; length -= 1) {
				read_uleb128(prog.rd)?;
			};
		};
	} else {
		const opcode = opcode - prog.head.opcode_base;
		const op_adv = opcode / prog.head.line_range;
		state.addr += (prog.head.min_instr_length * op_adv): uintptr;
		let line = state.line: int;
		line += prog.head.line_base: int +
			opcode: int % prog.head.line_range: int;
		state.line = line: uint;
	};
};
