// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use debug::image;
use io;
use path;

// Determines the file path, line number, and column number of a given address
// in the program image. Returns void if unknown. The return value is statically
// allocated.
export fn addr_to_line(
	image: *image::image,
	addr: uintptr,
) ((const str, uint, uint) | void | io::error) = {
	const dinfo_offs = match (arange_lookup(image, addr)) {
	case let offs: u64 =>
		yield offs;
	case =>
		return; // XXX: We could walk .debug_info I guess
	};
	const dinfo = match (read_debug_info(image, dinfo_offs)?) {
	case let rd: debug_info_reader =>
		yield rd;
	case =>
		return;
	};
	defer debug_info_finish(&dinfo);

	let comp_dir = "";
	let stmt_list = 0u64, found = false;
	for (!found) {
		const entry = match (debug_info_next(&dinfo)) {
		case io::EOF =>
			return;
		case let ent: entry =>
			yield ent;
		};
		defer entry_finish(&entry);

		if (entry.tag != DW_TAG_compile_unit) {
			continue;
		};

		for (const field &.. entry.fields) {
			switch (field.attr) {
			case DW_AT_stmt_list =>
				stmt_list = field.constant;
				found = true;
			case DW_AT_comp_dir =>
				comp_dir = field.string;
			case => void;
			};
		};
	};

	const prog = match (exec_line_program(image, stmt_list)) {
	case let prog: line_program =>
		yield prog;
	case =>
		return;
	};
	defer line_program_finish(&prog);

	let last = line_state { ... };
	for (const state => line_next(&prog)?) {
		defer last = state;

		if (state.file == 1) {
			continue;
		};
		if (state.addr < addr) {
			continue;
		};

		// If this is the first state we've seen, use it
		if (last.vm_loc != 0) {
			state = last;
		};

		if (state.file == 0) {
			return;
		};

		const file = &prog.head.files[state.file - 1];
		static let path = path::buffer { ... };

		path::set(&path)!;

		if (!path::abs(file.name)) {
			let dir = "";
			if (file.dir != 0) {
				dir = prog.head.dirs[file.dir - 1];
				if (!path::abs(dir) && comp_dir != "") {
					path::set(&path, comp_dir, dir)!;
				} else {
					path::set(&path, dir)!;
				};
			} else if (comp_dir != "") {
				path::set(&path, comp_dir)!;
			};
		};

		path::push(&path, file.name)!;
		return (path::string(&path), state.line, state.column);
	};
};
