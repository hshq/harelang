// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use debug::image;
use errors;
use encoding::hex;
use format::elf;
use io;
use memio;

// Supported version of .debug_aranges decoder
def ARANGES_VERSION: u16 = 2;

// Returns the debug_info offset for the DIE that corresponds to this address,
// if known, or void if unknown.
export fn arange_lookup(
	image: *image::image,
	addr: uintptr,
) (u64 | void | errors::invalid) = {
	const aranges = match (image::section_byname(image, ".debug_aranges")) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return;
	};

	// Read all arange tables in this section
	const rd = image::section_reader(image, aranges);
	for (const rd => new_table_reader(&rd, true)!) {
		match (arange_match(&rd, addr)) {
		case void => void;
		case let u: u64 =>
			return u;
		case io::error =>
			return errors::invalid;
		};
	};
};

fn arange_match(rd: *table_reader, addr: uintptr) (u64 | void | io::error) = {
	const ver = read_uhalf(rd)?;
	const info_offset = read_secword(rd)?;
	const asize = read_ubyte(rd)?;
	const ssize = read_ubyte(rd)?;
	assert(ver == ARANGES_VERSION, "debug::dwarf: unsupported .debug_ranges version");
	assert(ssize == 0, "debug::dwarf: unsupported segmented target for .debug_aranges");
	assert(asize == 8, "debug::dwarf: unsupported address size for .debug_aranges");

	read_align(rd, asize * 2)?;

	const au64 = addr: u64;
	for (!read_iseof(rd)) {
		const min = read_ulong(rd)?;
		const length = read_ulong(rd)?;
		if (min == 0 && length == 0) {
			if (!read_iseof(rd)) {
				return errors::invalid;
			};
			break;
		};
		const max = min + length;
		if (min <= au64 && max > au64) {
			return info_offset;
		};
	};
};
