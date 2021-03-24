use io;
use fmt;
use hare::ast;

// TODO
export fn expr(
	out: *io::stream,
	indent: size,
	t: ast::expr
) (size | io::error) = {
	let e = t as ast::constant_expr;
	assert(e is void);
	return fmt::fprint(out, "void")?;
};
