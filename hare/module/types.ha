// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use fs;
use hare::ast;
use hare::parse;
use hare::unparse;
use io;
use memio;
use path;
use strings;

// A module was not found.
export type not_found = !void;

// A tag contains a dot.
export type tag_has_dot = !void;

// Generic badly formatted tag error.
export type tag_bad_format = !void;

// A dependency cycle error.
export type dep_cycle = ![]str;

// Two files in a module have the same basename and extension, and the
// same number of compatible tags with the input tagset, so it is unknown
// which should be used.
export type file_conflict = ![]str;

// Context for another error.
export type errcontext = !(str, *error);

// Tagged union of all possible error types. Must be freed with [[finish_error]]
// unless it's passed to [[strerror]].
export type error = !(
	fs::error |
	io::error |
	path::error |
	parse::error |
	utf8::invalid |
	file_conflict |
	not_found |
	dep_cycle |
	tag_has_dot |
	tag_bad_format |
	errcontext |
);

// A container struct for context, used by [[gather]].
export type context = struct {
	harepath: str,
	harecache: str,
	tags: []str,
};

// The location of a module
export type location = (*path::buffer | ast::ident);

// Returns a string representation of a [[location]]. The result must be freed
// by the caller.
export fn locstr(loc: location) str = {
	match (loc) {
	case let buf: *path::buffer =>
		return strings::dup(path::string(buf));
	case let id: ast::ident =>
		return unparse::identstr(id);
	};
};

// XXX: this shouldn't be necessary, the language should have some built-in way
// to carry context with errors
fn attach(ctx: str, e: error) errcontext = (ctx, alloc(e)): errcontext;

// Free the resources associated with an [[error]].
export fn finish_error(e: error) void = {
	match (e) {
	case let e: dep_cycle =>
		strings::freeall(e);
	case let e: file_conflict =>
		strings::freeall(e);
	case let ctx: errcontext =>
		finish_error(*ctx.1);
		free(ctx.0);
		free(ctx.1);
	case => void;
	};
};

// Turns an [[error]] into a human-readable string. The result is
// statically allocated. Consumes the error.
export fn strerror(e: error) str = {
	defer finish_error(e);
	static let buf: [2*path::MAX]u8 = [0...];
	let buf = memio::fixed(buf[..]);
	_strerror(e, &buf);
	return memio::string(&buf)!;
};

fn _strerror(e: error, buf: *memio::stream) void = {
	let s = match (e) {
	case let e: fs::error =>
		yield fs::strerror(e);
	case let e: io::error =>
		yield io::strerror(e);
	case let e: parse::error =>
		yield parse::strerror(e);
	case let e: path::error =>
		yield path::strerror(e);
	case utf8::invalid =>
		yield "Invalid UTF-8";
	case not_found =>
		yield "Module not found";
	case tag_has_dot =>
		yield "Tag contains a '.'";
	case tag_bad_format =>
		yield "Bad tag format";
	case let e: dep_cycle =>
		memio::concat(buf, "Dependency cycle: ")!;
		memio::join(buf, " -> ", e...)!;
		return;
	case let e: file_conflict =>
		memio::concat(buf, "File conflict: ")!;
		memio::join(buf, ", ", e...)!;
		return;
	case let ctx: errcontext =>
		memio::concat(buf, ctx.0, ": ")!;
		_strerror(*ctx.1, buf);
		return;
	};
	memio::concat(buf, s)!;
};
