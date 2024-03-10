// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use getopt;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::types;
use hare::unparse;
use io;
use memio;
use os;
use path;
use strings;

fn typeinfo(
	store: *types::typestore,
	s: str,
) (void | io::error | parse::error | types::deferred | types::error) = {
	const hatype = if (s == "null") {
		fmt::println("null")?;
		yield types::lookup_builtin(store, ast::builtin_type::NULL);
	} else {
		let stream = memio::fixed(strings::toutf8(s));
		defer io::close(&stream)!;
		let sc = bufio::newscanner(&stream);
		defer bufio::finish(&sc);
		let lexer = lex::init(&sc, "-");
		const atype = parse::_type(&lexer)?;
		defer ast::type_finish(&atype);
		const typ = types::lookup(store, &atype)?;
		unparse::_type(os::stdout, &unparse::syn_nowrap, &atype)?;
		fmt::println()?;
		yield typ;
	};
	fmt::println("\tid:", hatype.id)?;
	fmt::println("\tsize:",
		if (hatype.sz == types::SIZE_UNDEFINED) "undefined"
		else hatype.sz)?;
	fmt::println("\talign:",
		if (hatype._align == types::SIZE_UNDEFINED) "undefined"
		else hatype._align)?;
};

fn str_to_arch(name: str) types::arch = {
	switch (name) {
	case "aarch64" =>
		return types::aarch64;
	case "riscv64" =>
		return types::riscv64;
	case "x86_64" =>
		return types::x86_64;
	case =>
		fmt::fatal("Unsupported architecture", name);
	};
};

export fn main() void = {
	let arch = os::arch_name(os::architecture());
	let arch = str_to_arch(arch);

	const help: []getopt::help = [
		"prints information about Hare types",
		('m', "arch", "set target architecture (x86_64, aarch64, riscv64)"),
		"types...",
	];
	const cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);
	for (let i = 0z; i < len(cmd.opts); i += 1) {
		const opt = cmd.opts[i];
		switch (opt.0) {
		// TODO: tags
		case 'm' =>
			arch = str_to_arch(opt.1);
		case => abort(); // unreachable
		};
	};
	if (len(cmd.args) == 0) {
		const name = path::basename(os::args[0]);
		getopt::printusage(os::stderr, name, help)!;
		os::exit(1);
	};

	const store = types::store(arch, null, null);
	defer types::store_free(store);
	for (let i = 0z; i < len(cmd.args); i += 1) {
		match (typeinfo(store, cmd.args[i])) {
		case void => void;
		case let err: io::error =>
			fmt::fatal("I/O error:", io::strerror(err));
		case let err: parse::error =>
			fmt::fatal(parse::strerror(err));
		case let err: types::error =>
			fmt::fatal(types::strerror(err));
		case types::deferred =>
			fmt::fatal("Invalid type");
		};
	};
};
