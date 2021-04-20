use hare::ast;
use hare::module;

type symkind = enum {
	LOCAL,
	MODULE,
	SYMBOL,
};

// Resolves a reference. Given an identifier, determines if it refers to a local
// symbol, a module, or a symbol in a remote module, then returns this
// information combined with a corrected ident if necessary.
fn resolve(ctx: *context, what: ast::ident) ((ast::ident, symkind) | void) = {
	if (is_local(ctx, what)) {
		return (what, symkind::LOCAL);
	};

	if (len(what) > 1) {
		// Look for symbol in remote module
		let partial = what[..len(what) - 1];

		match (module::lookup(ctx.mctx, partial)) {
			ver: module::version => {
				return (what, symkind::SYMBOL);
			},
			_: module::error => void,
		};
	};

	match (module::lookup(ctx.mctx, what)) {
		ver: module::version => {
			return (what, symkind::MODULE);
		},
		_: module::error => void,
	};

	return;
};

fn is_local(ctx: *context, what: ast::ident) bool = {
	if (len(what) != 1) {
		return false;
	};

	const summary = ctx.summary;
	for (let i = 0z; i < len(summary.types); i += 1) {
		const name = decl_ident(summary.types[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.errors); i += 1) {
		const name = decl_ident(summary.errors[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.globals); i += 1) {
		const name = decl_ident(summary.globals[i])[0];
		if (name == what[0]) {
			return true;
		};
	};
	for (let i = 0z; i < len(summary.funcs); i += 1) {
		const name = decl_ident(summary.funcs[i])[0];
		if (name == what[0]) {
			return true;
		};
	};

	return false;
};
