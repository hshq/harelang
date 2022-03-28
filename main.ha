use bufio;
use crypto::sha256;
use encoding::hex;
use fmt;
use hare::ast;
use hare::lex;
use hare::module2;
use hare::module2::{tag_mode};
use hare::parse;
use hare::unparse;
use io;
use os;
use strings;
use time;

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

	let cache = match (module2::load(&ctx, ident)) {
	case let err: module2::error =>
		fmt::errorf("Error scanning ")!;
		unparse::ident(os::stderr, ident)!;
		fmt::fatal(": {}", module2::strerror(err));
	case let mods: []module2::module =>
		yield mods;
	};
	defer module2::modules_finish(cache);

	fmt::printfln("Cached versions of {}:", os::args[1])!;
	for (let i = 0z; i < len(cache); i += 1) {
		const mod = &cache[i];
		fmt::print("Cache key: ")!;
		hex::encode(os::stdout, mod.cachekey)!;
		fmt::println()!;
		fmt::print("ABI key: ")!;
		hex::encode(os::stdout, mod.abi)!;
		fmt::println()!;
		fmt::printfln("Base directory: {}", mod.base)!;
	};
};
