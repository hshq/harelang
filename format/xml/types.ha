// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bufio;
use encoding::utf8;
use io;
use os;
use strio;

export type parser = struct {
	in: *bufio::bufstream,
	buf: [os::BUFSIZ]u8,
	close: bool,
	state: state,
	tags: []str,

	// strio buffers:
	namebuf: strio::dynamic_stream,
	entbuf: strio::dynamic_stream,
	textbuf: strio::dynamic_stream,
};

export type state = enum {
	ROOT,
	ELEMENT,
	ATTRS,
};

// The start of an XML element, e.g. <example
export type elementstart = str;

// The end of an XML element, e.g. /> or </example>
export type elementend = str;

// An attribute of an XML element, e.g. foo="bar"
export type attribute = (str, str);

// Text content of an XML element, e.g. baz or <![CDATA[baz]]>
export type text = str;

// Any valid XML token
export type token = (elementstart | elementend | attribute | text);

// A syntax error was encountered in the document.
export type syntaxerr = !void; // TODO: Add line number?

// Any error which can occur during XML parsing.
export type error = !(syntaxerr | utf8::invalid | io::error);

// Converts an [[error]] to a user-friendly string representation.
export fn strerror(err: error) const str = match (err) {
case syntaxerr =>
	yield "Syntax error";
case utf8::invalid =>
	yield "Document is not valid UTF-8";
case let err: io::error =>
	yield io::strerror(err);
};
