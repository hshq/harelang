// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use debug::image;
use format::elf;
use io;
use types::c;

export type string_table = struct {
	data: []u8,
};

// Loads a DWARF string table from .debug_str.
export fn load_strings(
	image: *image::image,
) (string_table | void | io::error) = {
	const sec = match (image::section_byname(image, ".debug_str")) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return;
	};
	return string_table {
		data = image::section_data(image, sec),
	};
};

// Returns a string from the string table.
export fn get_strp(table: *string_table, offs: u64) const str = {
	const string = &table.data[offs]: *const c::char;
	return c::tostr(string)!;
};
