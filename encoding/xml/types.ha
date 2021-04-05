use encoding::utf8;
use io;

// A syntax error was encountered in the document.
export type syntaxerr = void!; // TODO: Add line number?

// Any error which can occur during XML parsing.
export type error = (syntaxerr | utf8::invalid | io::error)!;

// Represents the state for an XML parser.
export type parser = struct {
	orig: *io::stream,
	in: *io::stream,
	buf: [4096]u8,
};

// Converts an [error] to a user-friendly string representation.
export fn strerror(err: error) const str = {
	return match (err) {
		syntaxerr => "Syntax error",
		utf8::invalid => "Document is not valid UTF-8",
		err: io::error => io::strerror(err),
	};
};
