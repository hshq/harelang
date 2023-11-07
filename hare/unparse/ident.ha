// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use io;
use memio;

// Unparses an identifier.
export fn ident(out: io::handle, id: ast::ident) (size | io::error) = {
	let ctx = context {
		out = out,
		...
	};
	return _ident(&ctx, &syn_nowrap, id, synkind::IDENT);
};

fn _ident(
	ctx: *context,
	syn: *synfunc,
	id: ast::ident,
	kind: synkind,
) (size | io::error) = {
	let n = 0z;
	for (let i = 0z; i < len(id); i += 1) {
		n += syn(ctx, id[i], kind)?;
		if (i + 1 < len(id)) {
			n += syn(ctx, "::", kind)?;
		};
	};
	return n;
};

// Unparses an identifier into a string. The caller must free the return value.
export fn identstr(id: ast::ident) str = {
	let buf = memio::dynamic();
	ident(&buf, id)!;
	return memio::string(&buf)!;
};

@test fn ident() void = {
	let s = identstr(["foo", "bar", "baz"]);
	defer free(s);
	assert(s == "foo::bar::baz");

	let s = identstr(["foo"]);
	defer free(s);
	assert(s == "foo");
};
