// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use ascii;
use fmt;
use getopt;
use os;
use shlex;
use strings;

fn version(name: str, cmd: *getopt::command) (void | error) = {
	let verbose = 0;
	for (let opt .. cmd.opts) {
		switch (opt.0) {
		case 'v' =>
			verbose += 1;
		case => abort();
		};
	};

	let build_arch = os::arch_name(os::architecture());
	let build_arch = get_arch(build_arch)!;
	let build_platform = ascii::strlower(os::sysname());

	switch (verbose) {
	case 0 =>
		fmt::printfln("hare {}", VERSION)!;
	case 1 =>
		fmt::printfln("hare {}", VERSION)!;

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
	case =>
		const version = shlex::quotestr(VERSION);
		defer free(version);
		const harepath = shlex::quotestr(harepath());
		defer free(harepath);

		fmt::printfln(`VERSION={}`, version)!;
		fmt::printfln(`DEFAULT_TAGS="+{}+{}"`, build_arch.name, build_platform)!;
		fmt::printfln(`HAREPATH={}`, harepath)!;

		let toolchains: []str = [];
		defer free(toolchains);

		for (let arch .. arches) {
			append(toolchains, arch.name);
		};

		const toolchains = strings::join(" ", toolchains...);
		defer free(toolchains);
		fmt::printfln(`TOOLCHAINS="{}"`, toolchains)!;

		for (let arch .. arches) {
			const name = ascii::strupper(arch.name);
			const as_cmd = shlex::quotestr(arch.as_cmd);
			const cc_cmd = shlex::quotestr(arch.cc_cmd);
			const ld_cmd = shlex::quotestr(arch.ld_cmd);
			defer free(name);
			defer free(as_cmd);
			defer free(cc_cmd);
			defer free(ld_cmd);

			fmt::printfln("{}_AS={}", name, as_cmd)?;
			fmt::printfln("{}_CC={}", name, cc_cmd)?;
			fmt::printfln("{}_LD={}", name, ld_cmd)?;
		};
	};
};
