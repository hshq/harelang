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
	for (let opt .. cmd.opts) {
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
	for (let s => strings::next_token(&tok)) {
		fmt::printfln("\t{}", s)?;
	};

	fmt::println("toolchains:")?;
	for (let arch .. arches) {
		fmt::printfln(" {}:", arch.name)?;
		fmt::printfln("\tAS={}", arch.as_cmd)?;
		fmt::printfln("\tCC={}", arch.cc_cmd)?;
		fmt::printfln("\tLD={}", arch.ld_cmd)?;
	};
};
