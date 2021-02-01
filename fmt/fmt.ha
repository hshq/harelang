// A format string consists of a string of literal characters, to be printed
// verbatim, and format sequences, which describe how to format arguments from
// a set of variadic parameters for printing.
//
// A format sequence is enclosed in curly braces '{}'. An empty sequence takes
// the next argument from the parameter list, in order. A specific parameter can
// be used by numbering it from zero: '{0}', '{1}', and so on. A colon may be
// used to specify additional constraints on the format in a type-specific
// manner: '{0:x} will print a number in hexadecimal.
//
// TODO: Document this more I guess
use io;
use types;

// Tagged union of all types which are formattable.
export type formattable = (...types::numeric | uintptr | str | *void);

// Formats text for printing and writes it to an [io::stream].
export fn fprintf(s: *io::stream, fmt: str,
		args: formattable...) (io::error | size) = {
	return io::unsupported: io::error; // TODO: Blocked on rune picking
};
