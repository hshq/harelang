// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use debug::image;
use errors;
use format::elf;
use io;
use memio;
use sort;

export type abbrev_table = struct {
	items: []abbrev,
};

// A single abbreviated tag from a .debug_abbrev section.
export type abbrev = struct {
	code: u64,
	tag: u32,
	has_children: bool,
	fields: []afield,
};

// A field in a .debug_abbrev section
export type afield = struct {
	attr: u32,
	form: u32,
};

// Loads an abbreviation table from the .debug_abbrev section, loading the table
// at the provided offset from the start of the ELF section.
//
// Pass the result to [[abbrev_table_finish]] to free resources associated with
// the table when you're done with it.
export fn load_abbrevs(
	image: *image::image,
	offs: u64,
) (abbrev_table | void | errors::invalid) = {
	const sec = match (image::section_byname(image, ".debug_abbrev")) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return;
	};

	const rd = image::section_reader(image, sec);
	io::seek(&rd, offs: io::off, io::whence::SET)!;
	const rd = new_table_reader(&rd, false)! as table_reader;

	let abbrevs: []abbrev = [];
	for (true) {
		match (read_abbrev(&rd)) {
		case io::EOF => break;
		case io::error => return errors::invalid;
		case let ab: abbrev =>
			append(abbrevs, ab);
		};
	};

	return abbrev_table {
		items = abbrevs,
	};
};

// Reads an entry from an abbreviation table.
fn read_abbrev(
	rd: *table_reader,
) (abbrev | io::EOF | io::error) = {
	const code = read_uleb128(rd)?;
	if (code == 0) {
		return io::EOF;
	};
	const tag = read_uleb128(rd)?;
	const children = read_ubyte(rd)? != 0;

	let fields: []afield = [];
	for (true) {
		const name = read_uleb128(rd)?;
		const form = read_uleb128(rd)?;
		if (name == 0 && form == 0) {
			break;
		};
		append(fields, afield {
			attr = name: u32,
			form = form: u32,
		});
	};

	return abbrev {
		code = code,
		tag = tag: u32,
		has_children = children,
		fields = fields,
	};
};

// Frees resources associated with an [[abbrev_table]].
export fn abbrev_table_finish(table: *abbrev_table) void = {
	for (let i = 0z; i < len(table.items); i += 1) {
		free(table.items[i].fields);
	};
	free(table.items);
};

// Retrieves an abbreviation from an [[abbrev_table]] by its abbreviation code.
export fn get_abbrev(table: *abbrev_table, code: u64) const nullable *abbrev = {
	// TODO: Sort the list and do this faster
	for (let item &.. table.items) {
		if (item.code == code) {
			return item;
		};
	};
	return null;
};
