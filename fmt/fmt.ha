// A format string consists of a string of literal characters, to be printed
// verbatim, and format sequences, which describe how to format arguments from
// a set of variadic parameters for printing.
//
// A format sequence is enclosed in curly braces '{}'. An empty sequence takes
// the next argument from the parameter list, in order. A specific parameter may
// be selected by indexing it from zero: '{0}', '{1}', and so on. To print '{',
// use '{{', and for '}', use '}}'.
//
// You may use a colon to add format modifiers; for example, '{:x}' will format
// an argument in hexadecimal, and '{3:-10}' will left-align the 3rd argument to
// at least 10 characters.
//
// The format modifiers takes the form of an optional flag character:
//
// 0: Numeric values are zero-padded up to the required width.
// -: The value shall be left-aligned, and spaces inserted on the right to meet
//    the required width. '-' takes precedence over '0' if both are used.
//  : (a space) insert a space before positive numbers, where '-' would be if it
//    were negative.
// +: insert a '+' before positive numbers, where '-' would be if it were
//    negative. '+' takes precedence over ' ' if both are used.
//
// Following the flag, an optional decimal number shall specify the minimum
// width of this field. If '0' or '-' were not given, the default behavior shall
// be to pad with spaces to achieve the necessary width.
//
// Following the width, an optional precision may be given as a decimal number
// following a '.' character. For integer types, this gives the minimum number
// of digits to include. For floating types, this gives the number of digits
// following the radix to include.
//
// Following the precision, an optional character controls the output format:
//
// x, X: print in lowercase or uppercase hexadecimal
// o, b: print in octal or binary
//
// TODO: Expand this with more format modifiers
use ascii;
use encoding::utf8;
use io;
use os;
use strconv;
use strings;
use types;

// Tagged union of all types which are formattable.
export type formattable = (...types::numeric | uintptr
	| str | rune | nullable *void);

// Formats text for printing writes it to [os::stdout].
export fn printf(fmt: str, args: formattable...) (io::error | size) =
	fprintf(os::stdout, fmt, args...);

// Formats text for printing writes it to [os::stderr].
export fn errorf(fmt: str, args: formattable...) (io::error | size) =
	fprintf(os::stderr, fmt, args...);

type base = enum {
	DECIMAL,
	LOWER_HEX,
	UPPER_HEX,
	OCTAL,
	BINARY,
};

type negation = enum {
	NONE,
	SPACE,
	PLUS,
};

type padding = enum {
	ALIGN_RIGHT,
	ALIGN_LEFT,
	ZEROES,
};

type modifiers = struct {
	padding:   padding,
	negation:  negation,
	width:     uint,
	precision: uint,
	base:      base,
};

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

		if (r == '{') {
			r = match (strings::next(&iter)) {
				void => abort("Invalid format string (unterminated '{')"),
				r: rune => r,
			};

			const arg = if (r == '{') match (io::write(
					s, utf8::encode_rune('{'))) {
				err: io::error => return err,
				w: size => {
					n += w;
					continue;
				},
			} else if (ascii::isdigit(r)) {
				strings::push(&iter, r);
				args[scan_uint(&iter)];
			} else {
				strings::push(&iter, r);
				i += 1z;
				args[i - 1z];
			};

			let mod = modifiers { ... };
			r = match (strings::next(&iter)) {
				void => abort("Invalid format string (unterminated '{')"),
				r: rune => r,
			};
			switch (r) {
				':' => scan_modifiers(&iter, &mod),
				'}' => void,
				*   => abort("Invalid format string"),
			};

			format(s, arg, &mod);
		} else if (r == '}') {
			match (strings::next(&iter)) {
				void => abort("Invalid format string (hanging '}')"),
				r: rune => assert(r == '}', "Invalid format string (hanging '}')"),
			};

			match (io::write(s, utf8::encode_rune('}'))) {
				err: io::error => return err,
				w: size => {
					n += w;
				},
			};
		} else match (io::write(s, utf8::encode_rune(r))) {
			err: io::error => return err,
			w: size => {
				n += w;
			},
		};
	};

	return n;
};

fn format(
	out: *io::stream,
	arg: formattable,
	mod: *modifiers,
) void = match (arg) {
	s: str => io::write(out, strings::to_utf8(s)),
	r: rune => io::write(out, utf8::encode_rune(r)),
	n: types::numeric => {
		let s = strconv::numerictos(n);
		io::write(out, strings::to_utf8(s));
	},
	p: uintptr => {
		let s = strconv::uptrtos(p);
		io::write(out, strings::to_utf8(s));
	},
	v: nullable *void => match (v) {
		v: *void => {
			let mod = modifiers { base = base::LOWER_HEX, ... };
			format(out, v: uintptr, &mod);
		},
		null => format(out, "(null)", mod),
	},
};

fn scan_uint(iter: *strings::iterator) uint = {
	let num = alloc([]u8, [], 1z); // TODO: alloc slice w/o cap
	defer free(num);
	for (true) {
		let r = match (strings::next(iter)) {
			void => abort("Invalid format string (unterminated '{')"),
			r: rune => r,
		};

		if (ascii::isdigit(r)) {
			append(num, r: u32: u8);
		} else {
			strings::push(iter, r);
			match (strconv::stou(strings::from_utf8(num))) {
				(strconv::invalid | strconv::overflow) =>
					abort("Invalid format string (invalid index)"),
				u: uint => return u,
			};
		};
	};
	abort("unreachable");
};

fn scan_modifiers(iter: *strings::iterator, mod: *modifiers) void = {
	abort("TODO: format modifiers");
};
