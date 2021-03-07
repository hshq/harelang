use ascii;
use fs;
use hare::ast;
use hare::parse;
use io;
use path;
use strings;
use strio;

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

// Parses a set of build tags, returning void if the string is an invalid tag
// set. The caller must free the return value with [tags_free].
export fn parse_tags(in: str) ([]tag | void) = {
	let tags: []tag = [];
	// defer! tags_free(tags);
	let iter = strings::iter(in);
	for (true) {
		let t = tag { ... };
		let m = match (strings::next(&iter)) {
			void => break,
			r: rune => r,
		};
		t.mode = switch (m) {
			*   => return,
			'+' => tag_mode::INCLUSIVE,
			'-' => tag_mode::EXCLUSIVE,
		};
		let buf = strio::dynamic();
		for (true) match (strings::next(&iter)) {
			void => break,
			r: rune => {
				if (ascii::isalnum(r) || r == '_') {
					strio::append_rune(buf, r);
				} else {
					strings::push(&iter, r);
					break;
				};
			},
		};
		t.name = strio::finish(buf);
		append(tags, t);
	};
	return tags;
};

// Frees a set of tags.
export fn tags_free(tags: []tag) void = {
	for (let i = 0z; i < len(tags); i += 1) {
		free(tags[i].name);
	};
	free(tags);
};

// The manifest for a particular module, with some number of inputs, and
// versions.
export type manifest = struct {
	inputs: []input,
	versions: []version,
};

// A module version: a set of possible input files for that module.
export type version = struct {
	hash: []u8,
	depends: []ast::ident,
	inputs: []input,
};

export type filetype = enum {
	HARE,
	ASSEMBLY,
};

// An input to a module, generally a source file.
export type input = struct {
	hash: []u8,
	path: path::path,
	ft: filetype,
	stat: fs::filestat,
};

// The requested module could not be found.
export type module_not_found = void!;

// All possible error types.
export type error = (fs::error | io::error | parse::error | module_not_found)!;

export fn errstr(err: error) const str = match (err) {
	err: fs::error => fs::errstr(err),
	err: io::error => io::errstr(err),
	err: parse::error => parse::errstr(err),
	module_not_found => "Module not found",
};
