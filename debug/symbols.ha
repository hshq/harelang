// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use debug::image;
use io;
use format::elf;
use strings;
use types::c;

// Returns symbol information by name.
export fn symbol_byname(
	image: *image::image,
	name: str,
) (elf::sym64 | io::error | void) = {
	const strtab = match (image::section_byname(image, ".strtab")) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return;
	};
	const symtab = match (image::section_byname(image, ".symtab")) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return;
	};

	const st_name = scan_strtab(image, strtab, name) as u64;
	const data = image::section_data(image, symtab);
	const entsz = symtab.sh_entsize: size;
	const nsym = len(data) / entsz;
	for (let i = 0z; i < nsym; i += 1) {
		const sym = &data[i * entsz]: *elf::sym64;
		if (sym.st_name == st_name) {
			return *sym;
		};
	};
};

// Returns the symbol that occupies a given address.
export fn symbol_byaddr(
	image: *image::image,
	addr: uintptr,
) (elf::sym64 | io::error | void) = {
	const addr = addr: u64;
	const symtab = match (image::section_byname(image, ".symtab")) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return;
	};

	const data = image::section_data(image, symtab);
	const entsz = symtab.sh_entsize: size;
	const nsym = len(data) / entsz;
	for (let i = 0z; i < nsym; i += 1) {
		const sym = &data[i * entsz]: *elf::sym64;
		const min = sym.st_value;
		const max = sym.st_value + sym.st_size;
		if (min <= addr && addr < max) {
			return *sym;
		};
	};
};

// Returns the name of the given symbol, or void if the executable was stripped.
export fn symbol_name(
	image: *image::image,
	sym: *elf::sym64,
) (const str | io::error | void) = {
	const strtab = match (image::section_byname(image, ".strtab")) {
	case let sec: *elf::section64 =>
		yield sec;
	case null =>
		return;
	};
	const data = image::section_data(image, strtab);
	return c::tostr(&data[sym.st_name]: *const c::char)!;
};

// Scans a string table for a given name and returns the index of that name.
fn scan_strtab(
	image: *image::image,
	strtab: *elf::section64,
	name: str,
) (u64 | io::error | void) = {
	let buf: [4096]u8 = [0...];
	let namebuf: [MAX_SYMNAME]u8 = [0...];

	// Prepare a nul-terminated byte slice of the name
	let name = strings::toutf8(name);
	namebuf[..len(name)] = name;
	namebuf[len(name)] = 0;
	name = namebuf[..len(name)+1];

	const data = image::section_data(image, strtab);
	match (bytes::index(data, name)) {
	case let z: size =>
		return z: u64;
	case void => void;
	};
};
