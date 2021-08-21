use bufio;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::types;
use io;
use strings;

fn parse_expr(src: str) *ast::expr = {
	const stream = bufio::fixed(strings::toutf8(src), io::mode::READ);
	defer io::close(stream);
	const lexer = lex::init(stream, "<test>");
	return alloc(parse::expression(&lexer)!);
};

fn mktestctx() context = context {
	store = types::store(types::x86_64, null, null),
	scope = alloc(scope { ... }),
};

fn freetestctx(ctx: *context) void = {
	// TODO: Some of this should be in -test
	types::store_free(ctx.store);
};
