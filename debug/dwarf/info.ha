// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use debug::image;
use format::elf;
use io;
use memio;

def INFO_VERSION: u16 = 4;

export type debug_info_reader = struct {
	image: *image::image,
	abbrev: abbrev_table,
	strings: (string_table | void),
	mem: *memio::stream,
	rd: *table_reader,
};

// Reads the debug info from a DWARF image. Returns a [[debug_info_reader]],
// call [[debug_info_next]] to retrieve the next DIE.
//
// Pass the return value to [[debug_info_finish]] after you're done with it.
export fn read_debug_info(
	image: *image::image,
	offs: u64,
) (debug_info_reader | void | io::error) = {
	const sec = match (image::section_byname(image, ".debug_info")) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return;
	};

	const memrd = alloc(image::section_reader(image, sec));
	io::seek(memrd, offs: io::off, io::whence::SET)?;

	const rd = match (new_table_reader(memrd, true)?) {
	case let rd: table_reader =>
		yield alloc(rd);
	case io::EOF =>
		return;
	};

	const ver = read_uhalf(rd)!;
	const abbrev_offs = read_secword(rd)!;
	const asize = read_ubyte(rd)!;
	assert(ver <= INFO_VERSION, "debug::dwarf: unsupported .debug_info version");
	assert(asize == 8, "debug::dwarf: unsupported address size in .debug_info");

	const abbrevs = match (load_abbrevs(image, abbrev_offs)?) {
	case void => return;
	case let tab: abbrev_table =>
		yield tab;
	};

	return debug_info_reader {
		image = image,
		abbrev = abbrevs,
		strings = load_strings(image)?,
		mem = memrd,
		rd = rd,
	};
};

// Returns the next debug info [[entry]] (DIE) from a [[debug_info_reader]].
// Pass the return value to [[entry_finish]] when done.
export fn debug_info_next(di: *debug_info_reader) (entry | io::EOF) = {
	if (read_iseof(di.rd)) {
		return io::EOF;
	};

	let code = read_uleb128(di.rd)!;
	for (code == 0) {
		if (read_iseof(di.rd)) {
			return io::EOF;
		};
		code = read_uleb128(di.rd)!;
	};

	const ref = get_abbrev(&di.abbrev, code);
	assert(ref != null, "debug::dwarf: unknown abbreviated tag");
	return read_die(di, di.rd, ref as *abbrev)!;
};

// Frees resources associated with a [[debug_info_reader]].
export fn debug_info_finish(di: *debug_info_reader) void = {
	free(di.mem);
	free(di.rd);
};

// A debug entry.
export type entry = struct {
	tag: u32,
	children: bool,
	fields: []field,
};

// Frees resources associated with an [[entry]].
export fn entry_finish(ent: *entry) void = {
	free(ent.fields);
};

// A debug [[entry]] field.
export type field = struct {
	attr: u32,
	form: u32,
	union {
		address: uintptr,
		block: []u8,
		constant: u64,
		string: const str,
		flag: bool,
		reference: u64,
		exprloc: []u8,
		ptr: u64,
	},
};

fn read_die(
	ir: *debug_info_reader,
	rd: *table_reader,
	abbrev: *abbrev,
) (entry | io::error) = {
	let fields: []field = [];
	for (const abf &.. abbrev.fields) {
		let field = field {
			attr = abf.attr,
			form = abf.form,
			...
		};
		let form = abf.form;
		for (form == DW_FORM_indirect) {
			form = read_uleb128(rd)?: u32;
		};

		// NOTE: Only supports up to DWARF 4 forms for now
		switch (form) {
		case DW_FORM_addr =>
			field.address = read_ulong(rd)?: uintptr;
		case DW_FORM_block =>
			field.block = read_slice(rd, read_uleb128(rd)?)?;
		case DW_FORM_block1 =>
			field.block = read_slice(rd, read_ubyte(rd)?)?;
		case DW_FORM_block2 =>
			field.block = read_slice(rd, read_uhalf(rd)?)?;
		case DW_FORM_block4 =>
			field.block = read_slice(rd, read_uword(rd)?)?;
		case DW_FORM_data1 =>
			field.constant = read_ubyte(rd)?;
		case DW_FORM_data2 =>
			field.constant = read_uhalf(rd)?;
		case DW_FORM_data4 =>
			field.constant = read_uword(rd)?;
		case DW_FORM_data8 =>
			field.constant = read_ulong(rd)?;
		case DW_FORM_udata =>
			field.constant = read_uleb128(rd)?;
		case DW_FORM_sdata =>
			field.constant = read_sleb128(rd)?: u64;
		case DW_FORM_string =>
			field.string = read_string(rd)?;
		case DW_FORM_strp =>
			// TODO: Look up in .debug_strings
			const offs = read_secword(rd)?;
			match (ir.strings) {
			case let tab: string_table =>
				field.string = get_strp(&tab, offs);
			case void =>
				field.string = "(unknown)";
			};
		case DW_FORM_flag =>
			field.flag = read_ubyte(rd)? != 0;
		case DW_FORM_flag_present =>
			field.flag = true;
		case DW_FORM_ref_addr =>
			field.reference = read_secword(rd)?;
		case DW_FORM_ref1 =>
			field.reference = read_ubyte(rd)?;
		case DW_FORM_ref2 =>
			field.reference = read_uhalf(rd)?;
		case DW_FORM_ref4 =>
			field.reference = read_uword(rd)?;
		case DW_FORM_ref8 =>
			field.reference = read_ulong(rd)?;
		case DW_FORM_ref_udata =>
			field.reference = read_uleb128(rd)?;
		case DW_FORM_ref_sig8 =>
			field.reference = read_ulong(rd)?;
		case DW_FORM_sec_offset =>
			field.reference = read_secword(rd)?;
		case DW_FORM_exprloc =>
			field.exprloc = read_slice(rd, read_uleb128(rd)?)?;
		case DW_FORM_indirect => abort();
		case => return errors::unsupported;
		};

		append(fields, field);
	};

	return entry {
		tag = abbrev.tag,
		children = abbrev.has_children,
		fields = fields,
	};
};
