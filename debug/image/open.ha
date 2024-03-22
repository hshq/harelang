// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;
use format::elf::{shn};
use io;

export type image = struct {
	fd: io::file,
	data: []u8,
	header: *elf::header64,
	// Cached sections
	shstrtab: nullable *elf::section64,
	symtab: nullable *elf::section64,
	strtab: nullable *elf::section64,
	debug_abbr: nullable *elf::section64,
	debug_aranges: nullable *elf::section64,
	debug_info: nullable *elf::section64,
	debug_line: nullable *elf::section64,
	debug_str: nullable *elf::section64,
};

// Opens an [[io::file]] as a program image.
export fn open(
	file: io::file,
) (image | io::error) = {
	const orig = io::tell(file)?;
	io::seek(file, 0, io::whence::END)?;
	const length = io::tell(file)?: size;
	io::seek(file, orig, io::whence::SET)?;

	const base = io::mmap(null, length,
		io::prot::READ,
		io::mflag::PRIVATE,
		file, 0z)?;

	const data = (base: *[*]u8)[..length];
	const head = base: *elf::header64;

	let shstrtab: nullable *elf::section64 = null;
	if (head.e_shstrndx != shn::UNDEF) {
		const shoffs = head.e_shoff + head.e_shstrndx * head.e_shentsize;
		shstrtab = &data[shoffs]: *elf::section64;
	};

	return image {
		fd = file,
		data = data,
		header = head,
		shstrtab = shstrtab,
		...
	};
};

// Closes a program [[image]].
export fn close(image: *image) void = {
	io::munmap(&image.data[0], len(image.data))!;
	io::close(image.fd)!;
};
