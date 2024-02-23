// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use ascii;
use bufio;
use fmt;
use getopt;
use os;
use strings;

fn version(name: str, cmd: *getopt::command) (void | error) = {
	let verbose = false;
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		const opt = cmd.opts[i];
		switch (opt.0) {
		case 'v' =>
			verbose = true;
		case => abort();
		};
	};

	fmt::printfln("hare {}", VERSION)!;
	if (!verbose) {
		return;
	};

	let build_arch = os::arch_name(os::architecture());
	let build_arch = get_arch(build_arch)!;
	let build_platform = ascii::strlower(os::sysname());

	fmt::printfln("build tags:\n\t+{}\n\t+{}\nHAREPATH{}:",
		build_arch.name, build_platform,
		if (os::getenv("HAREPATH") is str) " (from environment)" else "")?;

	let tok = strings::tokenize(harepath(), ":");
	for (true) match (strings::next_token(&tok)) {
	case void =>
		break;
	case let s: str =>
		fmt::printfln("\t{}", s)?;
	};

	fmt::println("toolchains:")?;
	for (let i = 0z; i < len(arches); i += 1) {
		fmt::printfln(" {}:", arches[i].name)?;
		fmt::printfln("\tAS={}", arches[i].as_cmd)?;
		fmt::printfln("\tCC={}", arches[i].cc_cmd)?;
		fmt::printfln("\tLD={}", arches[i].ld_cmd)?;
	};
};
