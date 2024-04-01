// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;
use format::elf::{sht};
use types::c;
use memio;

// Check that this section is actually a reference to this image.
fn section_validate(image: *image, sec: *elf::section64) void = {
	const addr = sec: uintptr;
	const min = &image.data[0]: uintptr;
	const max = min + len(image.data): uintptr;
	assert(min <= addr && max > addr, "section_name: invalid section");
};

// Returns a program section by name. Returns null if there is no such section,
// or if the section names are not available in this image (e.g. because it was
// stripped).
export fn section_byname(
	image: *image,
	name: str,
) nullable *elf::section64 = {
	const cached = [
		(".symtab", &image.symtab),
		(".strtab", &image.strtab),
		(".debug_abbr", &image.debug_abbr),
		(".debug_aranges", &image.debug_aranges),
		(".debug_info", &image.debug_info),
		(".debug_line", &image.debug_line),
		(".debug_str", &image.debug_str),
	];
	for (const (cand, val) .. cached) {
		if (cand == name) {
			match (*val) {
			case null => break;
			case let sec: *elf::section64 =>
				return sec;
			};
		};
	};

	const head = image.header;
	let r: nullable *elf::section64 = null;
	for (let i = 0u16; i < head.e_shnum; i += 1) {
		const shoffs = head.e_shoff + i * head.e_shentsize;
		const sec = &image.data[shoffs]: *elf::section64;
		if (sec.sh_type == sht::NULL) {
			continue;
		};

		const cand = section_name(image, sec);
		if (cand == name) {
			r = sec;
			break;
		};
	};

	match (r) {
	case null =>
		return null;
	case let sec: *elf::section64 =>
		for (let (cand, val) .. cached) {
			if (cand == name) {
				*val = sec;
				break;
			};
		};
	};

	return r;
};

// Returns the name of this [[elf::section64]], returning "" if the section
// names are not available in this image (i.e. it has been stripped).
export fn section_name(
	image: *image,
	sec: *elf::section64,
) const str = {
	section_validate(image, sec);

	const shtab = match (image.shstrtab) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return "";
	};

	const offs = shtab.sh_offset + sec.sh_name;
	return c::tostr(&image.data[offs]: *const c::char)!;
};

// Returns a slice of the data contained with a given section.
export fn section_data(image: *image, sec: *elf::section64) []u8 = {
	section_validate(image, sec);
	return image.data[sec.sh_offset..sec.sh_offset+sec.sh_size];
};

// Returns a [[memio::fixed]] reader for the given section.
export fn section_reader(image: *image, sec: *elf::section64) memio::stream = {
	const data = section_data(image, sec);
	return memio::fixed(data);
};
