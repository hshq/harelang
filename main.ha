use bufio;
use encoding::hex;
use fmt;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::module2;
use hare::module2::{tag_mode};
use hare::unparse;
use io;
use os;
use strings;

export fn main() void = {
	const conf = module2::config {
		fs = os::cwd,
		tags = [
			module2::tag {
				name = "linux",
				mode = tag_mode::INCLUSIVE,
			},
			module2::tag {
				name = "x86_64",
				mode = tag_mode::INCLUSIVE,
			},
		],
		...
	};
	const ctx = module2::newcontext(&conf);
	defer module2::context_finish(&ctx);

	const input = bufio::fixed(strings::toutf8(os::args[1]), io::mode::READ);
	const lexer = lex::init(&input, "<arg>");
	const ident = match (parse::ident(&lexer)) {
	case let err: parse::error =>
		fmt::fatal("Error parsing identifier: {}",
			parse::strerror(err));
	case let id: ast::ident =>
		yield id;
	};
	defer ast::ident_free(ident);

	const path = match (module2::resolve(&ctx, ident)) {
	case let err: module2::error =>
		fmt::errorf("Error resolving ")!;
		unparse::ident(os::stderr, ident)!;
		fmt::fatal(": {}", module2::strerror(err));
	case let path: str =>
		yield path;
	};
	defer free(path);

	let mod = match (module2::scan(&ctx, path)) {
	case let err: module2::error =>
		fmt::errorf("Error scanning ")!;
		unparse::ident(os::stderr, ident)!;
		fmt::fatal(": {}", module2::strerror(err));
	case let mod: module2::module =>
		yield mod;
	};

	fmt::printfln("Base: {}", mod.base)!;

	fmt::print("ABI hash: ")!;
	hex::encode(os::stdout, mod.abi)!;
	fmt::println()!;

	fmt::println("Dependencies:")!;
	for (let i = 0z; i < len(mod.depends); i += 1) {
		const depend = mod.depends[i];
		fmt::print("- ")!;
		unparse::ident(os::stdout, depend)!;
		fmt::println()!;
	};

	fmt::println("Input files:")!;
	for (let i = 0z; i < len(mod.inputs); i += 1) {
		fmt::printf("- {} ", mod.inputs[i].path)!;
		hex::encode(os::stdout, mod.inputs[i].hash)!;
		fmt::println()!;
	};
};
