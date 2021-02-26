use fs;
use hare::ast;
use os;
use path;

export type context = struct {
	// Filesystem to use for the cache and source files.
	fs: *fs::fs,
	// List of paths to search, generally populated from HAREPATH plus some
	// baked-in default.
	paths: []str,
	// Path to the Hare cache, generally populated from HARECACHE and
	// defaulting to $XDG_CACHE_HOME/hare.
	cache: str,
	// Build tags to apply to this context.
	tags: []tag,
};

// Initializes a new context with the system default configuration.
export fn context_init(tags: []tag) context = {
	let ctx = context {
		fs = os::cwd,
		tags = tags,
		...
	};
	// TODO: Insert default variables, look up environment, w/e
	return ctx;
};

// Converts an identifier to a partial path (e.g. foo::bar becomes foo/bar). The
// return value must be freed by the caller.
export fn ident_path(name: ast::ident) path::path = {
	let p = path::join(name[0]);
	for (let i = 1z; i < len(name); i += 1) {
		let q = path::join(p, name[i]);
		path::path_free(p);
		p = q;
	};
	return p;
};

@test fn ident_path() void = {
	let ident: ast::ident = ["foo", "bar", "baz"];
	let p = ident_path(ident);
	defer path::path_free(p);
	assert(path::equal(p, "foo/bar/baz"));
};
