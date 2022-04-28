// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use fs;
use hare::ast;
use hare::parse;
use io;
use fmt;

// The inclusive/exclusive state for a build tag.
export type tag_mode = enum {
	INCLUSIVE,
	EXCLUSIVE,
};

// A build tag, e.g. +x86_64.
export type tag = struct {
	name: str,
	mode: tag_mode,
};

// The manifest for a particular module, with some number of inputs, and
// versions.
export type manifest = struct {
	ident: ast::ident,
	inputs: []input,
	versions: []version,
};

// A module version: a set of possible input files for that module.
export type version = struct {
	hash: []u8,
	basedir: str,
	depends: []ast::ident,
	inputs: []input,
	subdirs: []str,
};

// The filetype of a file within a module.
export type filetype = enum {
	HARE,
	ASSEMBLY,
};

// An input to a module, generally a source file.
export type input = struct {
	hash: []u8,
	path: str,
	ft: filetype,
	stat: fs::filestat,

	// Name without any tags
	basename: str,
	// Tags applicable to input
	tags: []tag,
};

// The requested module could not be found.
export type notfound = !void;

// We are unable to select from two ambiguous options for an input file.
export type ambiguous = !(str, str);

// All possible error types.
export type error = !(
	fs::error |
	io::error |
	parse::error |
	notfound |
	ambiguous);

// Returns a human-friendly representation of an error.
export fn strerror(err: error) const str = {
	// Should be more than enough for PATH_MAX * 2
	static let buf: [4096]u8 = [0...];
	match (err) {
	case let err: fs::error =>
		return fs::strerror(err);
	case let err: io::error =>
		return io::strerror(err);
	case let err: parse::error =>
		return parse::strerror(err);
	case notfound =>
		return "Module not found";
	case let amb: ambiguous =>
		return fmt::bsprintf(buf, "Cannot choose between {} and {}",
			amb.0, amb.1);
	};
};
