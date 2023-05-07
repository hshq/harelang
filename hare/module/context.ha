// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use dirs;
use fmt;
use fs;
use glob;
use hare::ast;
use os;
use path;
use strings;
use strio;

export type context = struct {
	// Filesystem to use for the cache and source files.
	fs: *fs::fs,
	// List of paths to search, generally populated from HAREPATH plus some
	// baked-in defaults.
	paths: []str,
	// Path to the Hare cache, generally populated from HARECACHE and
	// defaulting to $XDG_CACHE_HOME/hare.
	cache: str,
	// Build tags to apply to this context.
	tags: []tag,
	// List of -D arguments passed to harec
	defines: []str,
};

// Initializes a new context with the system default configuration. The tag list
// and list of defines (arguments passed with harec -D) is borrowed from the
// caller. The harepath parameter is not borrowed, but it is ignored if HAREPATH
// is set in the process environment.
export fn context_init(tags: []tag, defs: []str, harepath: str) context = {
	let ctx = context {
		fs = os::cwd,
		tags = tags,
		defines = defs,
		paths = {
			let harepath = match (os::getenv("HAREPATH")) {
			case void =>
				yield harepath;
			case let s: str =>
				yield s;
			};

			let path: []str = [];
			let tok = strings::tokenize(harepath, ":");
			for (true) match (strings::next_token(&tok)) {
			case void =>
				break;
			case let s: str =>
				append(path, strings::dup(s));
			};

			let vendor = glob::glob("vendor/*");
			defer glob::finish(&vendor);
			for (true) match (glob::next(&vendor)) {
			case void =>
				break;
			case glob::failure =>
				void; // XXX: Anything else?
			case let s: str =>
				append(path, strings::dup(s));
			};

			append(path, strings::dup("."));
			yield path;
		},
		cache: str = match (os::getenv("HARECACHE")) {
		case void =>
			yield strings::dup(dirs::cache("hare"));
		case let s: str =>
			yield strings::dup(s);
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
export fn identpath(name: ast::ident) str = {
	if (len(name) == 0) {
		return strings::dup(".");
	};
	let buf = path::init()!;
	for (let i = 0z; i < len(name); i += 1) {
		path::add(&buf, name[i])!;
	};
	return path::allocate(&buf);
};

@test fn identpath() void = {
	let ident: ast::ident = ["foo", "bar", "baz"];
	let p = identpath(ident);
	defer free(p);
	assert(p == "foo/bar/baz");
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
