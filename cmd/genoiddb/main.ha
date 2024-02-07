// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use bufio;
use fmt;
use io;
use os;
use strconv;
use strings;
use types;

type entry = struct {
	name: str,
	val: str,
	idx: size,
};

// Parses an oid database from stdin and writes the database as hare code to
// stdout.
export fn main() void = {
	let oids = parse_oids();
	defer free_oids(oids);

	fmt::println("// SPDX-License-Identifier: MPL-2.0\n"
		"// (c) Hare authors <https://harelang.org>\n"
		"// This is an auto generated file. Do not edit.\n"
		"\n"
		"use encoding::asn1;\n")!;

	fmt::println("const _db = asn1::oiddb {")!;

	write_db(os::stdout, oids)!;

	fmt::println("\tnames = [")!;
	for (let i = 0z; i < len(oids); i += 1) {
		fmt::printfln("\t\t\"{}\",", oids[i].name)!;
	};
	fmt::println("\t],")!;
	fmt::println("};\n")!;

	fmt::println("export const db = &_db;\n")!;

	for (let i = 0z; i < len(oids); i += 1) {
		fmt::print("export def ")!;
		write_varname(os::stdout, oids[i].name)!;
		fmt::printfln(": asn1::oid = {};", i)!;
	};
};

fn parse_oids() []entry = {
	let s = bufio::newscanner(os::stdin, types::SIZE_MAX);
	defer bufio::finish(&s);
	let oids: []entry = [];

	for (true) {
		const l = match (bufio::scan_line(&s)!) {
		case io::EOF =>
			break;
		case let s: const str =>
			yield s;
		};

		if (l == "" || strings::hasprefix(l, '#')) {
			continue;
		};


		const p = strings::split(l, " ");
		defer free(p);
		const name = p[0];
		const val = p[len(p)-1];

		append(oids, entry {
			name = strings::dup(name),
			val = strings::dup(val),
			...
		});
	};

	return oids;
};

fn free_oids(oids: []entry) void = {
	for (let i = 0z; i < len(oids); i += 1) {
		free(oids[i].name);
		free(oids[i].val);
	};

	free(oids);
};

fn write_db(h: io::handle, oids: []entry) (void | io::error) = {
	fmt::print("\tlut = [")?;

	const maxcols = 12z;
	let idx = 0z;

	for (let i = 0z; i < len(oids); i += 1) {
		let e = &oids[i];
		e.idx = idx;

		let der = oidtoder(e.val);
		assert(len(der) <= 0xff);
		insert(der[0], len(der): u8);
		defer free(der);

		for (let j = 0z; j < len(der); j += 1) {
			fmt::print(if (idx % maxcols == 0) "\n\t\t" else " ")?;
			fmt::printf("0x{:.2x},", der[j])?;
			idx += 1;
		};
	};
	fmt::println("\n\t],")?;

	const maxcols = 9z;
	fmt::print("\tindex = [")?;
	for (let i = 0z; i < len(oids); i += 1) {
		fmt::print(if (i % maxcols == 0) "\n\t\t" else " ")?;
		fmt::printf("0x{:.4x},", oids[i].idx)?;
	};
	fmt::println("\n\t],")?;
};

fn oidtoder(oid: str) []u8 = {
	let nums = oidtou64s(oid);
	defer free(nums);

	let der: []u8 = alloc([0...], 1);
	assert(nums[0] <= 6);
	assert(nums[1] < 40);
	der[0] = nums[0]: u8 * 40 + nums[1]: u8;
	let end = 1z;

	for (let i = 2z; i < len(nums); i += 1) {
		let n = nums[i];
		if (n == 0) {
			insert(der[end], 0u8);
			end = len(der);
			continue;
		};

		let first = true;
		for (n > 0) {
			let p: u8 = n: u8 & 0x7f;
			n >>= 7;
			if (first) {
				first = false;
			} else {
				p |= 0x80;
			};
			insert(der[end], p);
		};

		end = len(der);
	};

	return der;
};

fn oidtou64s(oid: str) []u64 = {
	let nums = strings::tokenize(oid, ".");
	let intnums: []u64 = [];

	for (true) {
		match (strings::next_token(&nums)) {
		case let s: str =>
			append(intnums, strconv::stou64(s)!);
		case void =>
			break;
		};
	};

	return intnums;
};

fn write_varname(h: io::handle, name: str) (void | io::error) = {
	// assume that names are in ascii
	let i = strings::iter(name);
	let prevlow = false;
	for (true) {
		match (strings::next(&i)) {
		case void =>
			break;
		case let r: rune =>
			let r = if (r == '-') {
				prevlow = false;
				yield '_';
			} else if (ascii::isdigit(r)) {
				prevlow = true;
				yield r;
			} else if (ascii::isupper(r)) {
				if (prevlow) {
					fmt::fprint(h, "_")?;
					prevlow = false;
				};
				yield r;
			} else if (ascii::islower(r)) {
				prevlow = true;
				yield ascii::toupper(r);
			} else {
				fmt::fatalf("Unexpected character in oid name: {}", r);
			};

			fmt::fprint(h, r)?;
		};
	};
};

