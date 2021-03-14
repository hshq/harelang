use dirs;
use fmt;
use fs;
use hare::ast;
use os;
use path;
use strings;
use strio;

// TODO: Specify this at build time once harec supports -D
def DEFAULT_HAREPATH: str = "/usr/src/hare";

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

// Initializes a new context with the system default configuration. The tag list
// is borrowed from the caller.
export fn context_init(tags: []tag) context = {
	let ctx = context {
		fs = os::cwd,
		tags = tags,
		paths: []str = match (os::getenv("HAREPATH")) {
			void => {
				let path: []str = alloc([
					strings::dup(DEFAULT_HAREPATH),
					dirs::data("hare"),
				]);
				path;
			},
			s: str => {
				let sl = strings::split(s, ":");
				let path: []str = alloc([], len(sl) + 1);
				for (let i = 0z; i < len(sl); i += 1) {
					append(path, strings::dup(sl[i]));
				};
				append(path, strings::dup("."));
				free(sl);
				path;
			},
		},
		cache: str = match (os::getenv("HARECACHE")) {
			void => dirs::cache("hare"),
			s: str => strings::dup(s),
		},
		...
	};
	return ctx;
};

// Frees resources associated with this context.
export fn context_finish(ctx: *context) void = {
	for (let i = 0z; i < len(ctx.paths); i += 1) {
		free(ctx.paths[i]);
	};
	free(ctx.paths);
	free(ctx.cache);
};

// Converts an identifier to a partial path (e.g. foo::bar becomes foo/bar). The
// return value must be freed by the caller.
export fn ident_path(name: ast::ident) str = {
	let p = path::join(name[0]);
	for (let i = 1z; i < len(name); i += 1) {
		let q = path::join(p, name[i]);
		free(p);
		p = q;
	};
	return p;
};

@test fn ident_path() void = {
	let ident: ast::ident = ["foo", "bar", "baz"];
	let p = ident_path(ident);
	defer free(p);
	assert(p == "foo/bar/baz");
};

// Joins an ident string with underscores instead of double colons. The return
// value must be freed by the caller.
//
// This is used for module names in environment variables and some file names.
export fn ident_underscore(ident: ast::ident) str = {
	let buf = strio::dynamic();
	for (let i = 0z; i < len(ident); i += 1) {
		fmt::fprintf(buf, "{}{}", ident[i],
			if (i + 1 < len(ident)) "_"
			else "") as size;
	};
	return strio::finish(buf);
};

@test fn ident_underscore() void = {
	let ident: ast::ident = ["foo", "bar", "baz"];
	let p = ident_underscore(ident);
	defer free(p);
	assert(p == "foo_bar_baz");
};
