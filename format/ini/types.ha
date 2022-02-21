// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use encoding::utf8;
use fmt;
use io;

// A syntax error occured during parsing.
export type syntaxerr = !size;

// Any error that may occur during parsing.
export type error = !(io::error | utf8::invalid | syntaxerr);

// Returns a user-friendly representation of [[error]].
export fn strerror(err: error) const str = match (err) {
case let err: io::error =>
	return io::strerror(err);
case utf8::invalid =>
	return "File is invalid UTF-8";
case let s: syntaxerr =>
	static let buf: [1024]u8 = [0...];
	yield fmt::bsprintf(buf, "{}: Invalid syntax", s: size);
};
