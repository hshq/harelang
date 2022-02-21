// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use fmt;
use hare::ast;
use io;
use strio;

// Unparses an identifier.
export fn ident(out: io::handle, id: ast::ident) (size | io::error) = {
	let n = 0z;
	for (let i = 0z; i < len(id); i += 1) {
		n += fmt::fprintf(out, "{}{}", id[i],
			if (i + 1 < len(id)) "::"
			else "")?;
	};
	return n;
};

// Unparses an identifier into a string. The caller must free the return value.
export fn identstr(id: ast::ident) str = {
	let buf = strio::dynamic();
	ident(&buf, id)!;
	return strio::string(&buf);
};

@test fn ident() void = {
	let s = identstr(["foo", "bar", "baz"]);
	assert(s == "foo::bar::baz");
	free(s);
	s = identstr(["foo"]);
	assert(s == "foo");
	free(s);
};
