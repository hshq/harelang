use hare::ast;
use os;
use path;

// Resolves the directory in which the given module resides for the provided
// context. The caller must free the return value.
export fn resolve(ctx: *context, ident: ast::ident) (str | error) = {
	let buf = path::init();
	for (let i = 0z; i < len(ctx.paths); i += 1) {
		void;
	};
	return modnotfound;
};
