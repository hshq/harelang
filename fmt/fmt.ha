// A format string consists of a string of literal characters, to be printed
// verbatim, and format sequences, which describe how to format arguments from
// a set of variadic parameters for printing.
//
// A format sequence is enclosed in curly braces '{}'. An empty sequence takes
// the next argument from the parameter list, in order. A specific parameter may
// be selected by indexing it from zero: '{0}', '{1}', and so on.
//
// You may use a colon to add format modifiers; for example, '{:x}' will format
// an argument in hexadecimal, and '{3:10}' will pad the 3rd argument to 10
// characters.
//
// TODO: Expand on format modifiers.
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

			const arg = switch (r) {
				':' => abort(), // TODO: format modifiers
				'}' => {
					i += 1z;
					args[i - 1z];
				},
				* => args[scan_uint(r, &iter)],
			};

			format(s, arg);
		} else {
			match (io::write(s, utf8::encode_rune(r))) {
				err: io::error => return err,
				w: size => {
					n += w;
				},
			};
		};
	};

	return n;
};

fn scan_uint(r: rune, iter: *strings::iterator) uint = {
	assert(ascii::isdigit(r));
	let num = alloc([]u8, [r: u32: u8], 1z); // XXX: alloc slice w/o cap
	defer free(num);
	for (true) {
		r = match (strings::next(iter)) {
			void => abort("Invalid format string (unterminated '(')"),
			r: rune => r,
		};
		switch (r) {
			*   => append(num, r: u32: u8),
			':' => abort(), // TODO: Format modifiers
			'}' => match (strconv::stou(strings::from_utf8(num))) {
				(strconv::invalid | strconv::overflow) =>
					abort("Invalid format string (invalid index)"),
				u: uint => return u,
			},
		};
	};
	abort("unreachable");
};

fn format(out: *io::stream, arg: formattable) void = match (arg) {
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
		v: *void => format(out, v: uintptr), // TODO: Hexadecimal
		null => format(out, "(null)"),
	},
};
