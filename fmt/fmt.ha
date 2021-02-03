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
// TODO: More detail
use encoding::utf8;
use io;
use os;
use strconv;
use strings;
use types;

// Tagged union of all types which are formattable.
export type formattable = (...types::numeric | uintptr | str | *void);

// Formats text for printing and writes it to an [io::stream].
export fn fprintf(
	s: *io::stream,
	fmt: str,
	args: formattable...
) (io::error | size) = {
	let n = 0z, i = 0z;
	let iter = strings::iter(fmt);
	for (true) {
		let r: rune = match (strings::next(&iter)) {
			void => break,
			r: rune => r,
		};

		if (r  == '{') {
			r = match (strings::next(&iter)) {
				void => abort("Invalid format string (unterminated '{')"),
				r: rune => r,
			};
			assert(r == '}'); // TODO
			format(s, args[i]);
			i += 1z;
			continue;
		};

		match (io::write(s, utf8::encode_rune(r))) {
			err: io::error => return err,
			w: size => {
				n += w;
			},
		};
	};

	return n;
};

// Formats text for printing writes it to [os::stdout].
export fn printf(fmt: str, args: formattable...) (io::error | size) =
	fprintf(os::stdout, fmt, args...);

// Formats text for printing writes it to [os::stderr].
export fn errorf(fmt: str, args: formattable...) (io::error | size) =
	fprintf(os::stderr, fmt, args...);

fn format(out: *io::stream, arg: formattable) void = match (arg) {
	s: str => io::write(out, strings::to_utf8(s)),
	v: *void => format(out, v: uintptr), // TODO: Hexadecimal
	p: uintptr => {
		let s = strconv::uptrtos(p);
		io::write(out, strings::to_utf8(s));
	},
	n: types::numeric => {
		let s = strconv::numerictos(n);
		io::write(out, strings::to_utf8(s));
	},
};
