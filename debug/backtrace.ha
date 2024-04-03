// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use debug::dwarf;
use debug::image;
use fmt;
use format::elf;
use fs;
use io;
use os;
use time;

def MAX_FRAMES_TOP: size = 16z;
def MAX_FRAMES_BOTTOM: size = 16z;
def MAX_FRAMES: size = MAX_FRAMES_TOP + MAX_FRAMES_BOTTOM;

fn backtrace(self: *image::image, frame: stackframe) void = {
	let orig = frame;
	let nframe = 1z;
	for (true; nframe += 1) {
		match (next(frame)) {
		case let next: stackframe =>
			frame = next;
		case done => break;
		};
	};
	frame = orig;

	const st = match (os::fstat(self.fd)) {
	case let st: fs::filestat =>
		yield st;
	case fs::error =>
		yield fs::filestat { mask = 0, ... };
	};

	static let seen: [MAX_FRAMES]uintptr = [0: uintptr...];
	let seen = seen[..0];

	for (let i = 0z; i < nframe; i += 1) {
		if (i < MAX_FRAMES_TOP || i > nframe - MAX_FRAMES_BOTTOM) {
			printframe(self, &seen, &st, frame);
		};
		if (i == MAX_FRAMES_TOP && nframe > MAX_FRAMES) {
			fmt::errorfln("\t({} additional frames omitted)",
				nframe - MAX_FRAMES): void;
		};

		match (next(frame)) {
		case let next: stackframe =>
			frame = next;
		case done =>
			break;
		};
	};
};

fn printframe(
	self: *image::image,
	seen: *[]uintptr,
	imgstat: *fs::filestat,
	frame: stackframe,
) void = {
	const pc = frame_pc(frame);

	// Try to translate the address
	match (translate(pc: uintptr)) {
	case let ptr: uintptr =>
		pc = ptr;
	case =>
		void;
	};

	const sym = match (symbol_byaddr(self, pc)) {
	case let sym: elf::sym64 =>
		yield sym;
	case =>
		fmt::errorfln("(unknown) [0x{:x}]", pc): void;
		return;
	};
	const name = match (symbol_name(self, &sym)) {
	case let name: const str =>
		yield name;
	case =>
		fmt::errorfln("(unknown) [0x{:x}]", pc): void;
		return;
	};

	// Look for DWARF line numbers, if possible
	const (path, line, col) = match (dwarf::addr_to_line(self, pc)) {
	case (void | io::error) =>
		// No line number available, print what we've got
		fmt::errorfln("{}+0x{:x} [0x{:x}]", symname_to_ident(name),
			pc - sym.st_value: uintptr, pc): void;
		return;
	case let tuple: (const str, uint, uint) =>
		yield tuple;
	};

	const file = match (os::open(path)) {
	case fs::error =>
		printframe_with_symbol(&sym, name, path, (line, col), pc);
		return;
	case let file: io::file =>
		yield file;
	};
	defer io::close(file)!;

	static let linebuf: [1024]u8 = [0...];
	const scan = bufio::newscanner_static(file, linebuf);

	let context = "";
	for (let i = 0u; i < line; i += 1) {
		match (bufio::scan_line(&scan)) {
		case let s: const str =>
			context = s;
		case io::EOF =>
			printframe_with_symbol(&sym, name, path, (line, col), pc);
			return;
		};
	};

	fmt::errorf("{}:{}:{} {}+0x{:x} [0x{:x}]",
		path, line, col, symname_to_ident(name),
		pc - sym.st_value: uintptr, pc): void;

	// Skip context on frames we've already printed
	for (let i = 0z; i < len(seen); i += 1) {
		if (seen[i] == pc) {
			fmt::errorfln(" (already shown)"): void;
			return;
		};
	};
	static append(seen, pc);
	fmt::errorln(): void;

	if (imgstat.mask & fs::stat_mask::MTIME != 0) {
		match (os::fstat(file)) {
		case let st: fs::filestat =>
			if (st.mask & fs::stat_mask::MTIME == 0) yield;
			if (time::compare(st.mtime, imgstat.mtime) == 1) {
				fmt::errorln("* Warning: file was modified after executable was built"): void;
			};
		case => void;
		};
	};

	fmt::errorfln("| {}", context): void;

	if (col != 0) {
		fmt::errorf("  "): void;
		for (let i = 1u; i < col - 1; i += 1) {
			fmt::errorf(" "): void;
		};
		fmt::errorf("^"): void;
	};

	fmt::errorln(): void;

};

fn printframe_with_symbol(
	sym: *elf::sym64,
	name: str,
	path: str,
	loc: (uint, uint),
	pc: uintptr,
) void = {
	fmt::errorfln("{}:{}:{} {}+0x{:x} [0x{:x}]",
		path, loc.0, loc.1, symname_to_ident(name),
		pc - sym.st_value: uintptr, pc): void;
	fmt::errorln(): void;
};
