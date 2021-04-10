use encoding::utf8;
use io;
use os;

// Represents the state for an XML parser.
export type parser = struct {
	orig: *io::stream,
	in: *io::stream,
	buf: [os::BUFSIZ]u8,
	state: state,
	// strio buffers:
	namebuf: *io::stream,
	entbuf: *io::stream,
	textbuf: *io::stream,
};

export type state = enum {
	ROOT,
	ELEMENT,
	ATTRS,
};

// The start of an XML element, e.g. <example
export type elementstart = str;

// The end of an XML element, e.g. /> or </example>
export type elementend = void;

// An attribute of an XML element, e.g. foo="bar"
export type attribute = (str, str);

// Text content of an XML element, e.g. baz or <![CDATA[baz]]>
export type text = str;

// Any valid XML token
export type token = (elementstart | elementend | attribute | text);

// A syntax error was encountered in the document.
export type syntaxerr = void!; // TODO: Add line number?

// Any error which can occur during XML parsing.
export type error = (syntaxerr | utf8::invalid | io::error)!;

// Converts an [error] to a user-friendly string representation.
export fn strerror(err: error) const str = {
	return match (err) {
		syntaxerr => "Syntax error",
		utf8::invalid => "Document is not valid UTF-8",
		err: io::error => io::strerror(err),
	};
};

export fn token_dup(tok: token) void = abort(); // TODO
