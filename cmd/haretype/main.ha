use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::types;
use hare::unparse;
use io;
use os;
use strings;

export fn main() void = {
	for (let i = 1z; i < len(os::args); i += 1) {
		const stream = bufio::fixed(
			strings::toutf8(os::args[i]),
			io::mode::READ);
		defer io::close(stream);
		const lexer = lex::init(stream, "-");
		const atype = parse::_type(&lexer)!;
		defer ast::type_free(atype);
		unparse::_type(os::stdout, 0, atype)!;
		fmt::println()!;
		const store = types::store(types::x86_64, null, null);
		defer types::store_free(store);
		const hatype = types::lookup(store, &atype)!;
		fmt::printfln("\tid: {}", hatype.id)!;
		fmt::printfln("\tsize: {}", hatype.sz)!;
		fmt::printfln("\talign: {}", hatype.align)!;
	};
};
