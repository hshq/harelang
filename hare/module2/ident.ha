use errors;
use fmt;
use hare::ast;
use path;
use strings;
use strio;

// Appends an identifier to a path buffer, such that foo::bar appends foo/bar/.
export fn identpath(
	buf: *path::buffer,
	ident: ast::ident,
) (void | errors::overflow) = {
	if (len(ident) == 0) {
		path::add(buf, ".")?;
	};
	for (let i = 0z; i < len(ident); i += 1) {
		path::add(buf, ident[i])?;
	};
};

@test fn identpath() void = {
	let ident: ast::ident = ["foo", "bar", "baz"];
	let buf = path::init();
	identpath(&buf, ident)!;
	assert(path::string(&buf) == "foo/bar/baz");
};

// Joins an ident string with underscores instead of double colons. The return
// value must be freed by the caller.
//
// This is used for module names in environment variables and some file names.
export fn identuscore(ident: ast::ident) str = {
	let buf = strio::dynamic();
	for (let i = 0z; i < len(ident); i += 1) {
		fmt::fprintf(&buf, "{}{}", ident[i],
			if (i + 1 < len(ident)) "_"
			else "") as size;
	};
	return strio::string(&buf);
};

@test fn identuscore() void = {
	let ident: ast::ident = ["foo", "bar", "baz"];
	let p = identuscore(ident);
	defer free(p);
	assert(p == "foo_bar_baz");
};
