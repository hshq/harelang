use fs;
use io;
use path;

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
	inputs: []input,
	versions: []version,
};

// A module version: a set of possible input files for that module.
export type version = struct {
	hash: str,
	inputs: []input,
};

// An input to a module, generally a source file.
export type input = struct {
	hash: str,
	path: path::path,
	stat: fs::filestat,
};

// The requested module could not be found.
export type module_not_found = void!;

// All possible error types.
export type error = (fs::error | io::error | module_not_found);

export fn errstr(err: error) const str = match (err) {
	err: fs::error => fs::errstr(err),
	err: io::error => io::errstr(err),
	module_not_found => "Module not found",
};
