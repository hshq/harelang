// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use encoding::utf8;
use io;
use math;
use memio;
use os;
use strconv;
use strings;
use types;

// Tagged union of the [[formattable]] types and [[mods]]. Used for
// functions which accept format strings.
export type field = (...formattable | *mods);

// Tagged union of all types which are formattable.
export type formattable = (...types::numeric | uintptr | str | rune | bool |
	nullable *opaque | void);

// Formats text for printing and writes it to [[os::stdout]].
export fn printf(fmt: str, args: field...) (size | io::error) =
	fprintf(os::stdout, fmt, args...);

// Formats text for printing and writes it to [[os::stdout]], followed by a line
// feed.
export fn printfln(fmt: str, args: field...) (size | io::error) =
	fprintfln(os::stdout, fmt, args...);

// Formats text for printing and writes it to [[os::stderr]].
export fn errorf(fmt: str, args: field...) (size | io::error) =
	fprintf(os::stderr, fmt, args...);

// Formats text for printing and writes it to [[os::stderr]], followed by a line
// feed.
export fn errorfln(fmt: str, args: field...) (size | io::error) =
	fprintfln(os::stderr, fmt, args...);

// Formats text for printing and writes it into a heap-allocated string. The
// caller must free the return value.
export fn asprintf(fmt: str, args: field...) str = {
	let buf = memio::dynamic();
	assert(fprintf(&buf, fmt, args...) is size);
	return strings::fromutf8_unsafe(memio::buffer(&buf));
};

// Formats text for printing and writes it into a caller supplied buffer. The
// returned string is borrowed from this buffer. Aborts if the buffer isn't
// large enough to hold the formatted text.
export fn bsprintf(buf: []u8, fmt: str, args: field...) str = {
	let sink = memio::fixed(buf);
	let l = fprintf(&sink, fmt, args...)!;
	return strings::fromutf8_unsafe(buf[..l]);
};

// Formats text for printing and writes it to [[os::stderr]], followed by a line
// feed, then exits the program with an error status.
export fn fatalf(fmt: str, args: field...) never = {
	fprintfln(os::stderr, fmt, args...)!;
	os::exit(255);
};

// Formats values for printing using the default format modifiers and writes
// them to [[os::stderr]] separated by spaces and followed by a line feed, then
// exits the program with an error status.
export fn fatal(args: formattable...) never = {
	fprintln(os::stderr, args...)!;
	os::exit(255);
};

// Formats text for printing and writes it to an [[io::handle]], followed by a
// line feed.
export fn fprintfln(
	h: io::handle,
	fmt: str,
	args: field...
) (size | io::error) = {
	return fprintf(h, fmt, args...)? + io::write(h, ['\n'])?;
};

// Formats values for printing using the default format modifiers and writes
// them to [[os::stdout]] separated by spaces.
export fn print(args: formattable...) (size | io::error) =
	fprint(os::stdout, args...);

// Formats values for printing using the default format modifiers and writes
// them to [[os::stdout]] separated by spaces and followed by a line feed.
export fn println(args: formattable...) (size | io::error) =
	fprintln(os::stdout, args...);

// Formats values for printing using the default format modifiers and writes
// them to [[os::stderr]] separated by spaces.
export fn error(args: formattable...) (size | io::error) =
	fprint(os::stderr, args...);

// Formats values for printing using the default format modifiers and writes
// them to [[os::stderr]] separated by spaces and followed by a line feed.
export fn errorln(args: formattable...) (size | io::error) =
	fprintln(os::stderr, args...);

// Formats values for printing using the default format modifiers and writes
// them into a heap-allocated string separated by spaces. The caller must free
// the return value.
export fn asprint(args: formattable...) str = {
	let buf = memio::dynamic();
	assert(fprint(&buf, args...) is size);
	return strings::fromutf8_unsafe(memio::buffer(&buf));
};

// Formats values for printing using the default format modifiers and writes
// them into a caller supplied buffer separated by spaces. The returned string
// is borrowed from this buffer. Aborts if the buffer isn't large enough to hold
// the formatted text.
export fn bsprint(buf: []u8, args: formattable...) str = {
	let sink = memio::fixed(buf);
	let l = fprint(&sink, args...)!;
	return strings::fromutf8_unsafe(buf[..l]);
};

// Formats values for printing using the default format modifiers and writes
// them to an [[io::handle]] separated by spaces and followed by a line feed.
export fn fprintln(h: io::handle, args: formattable...) (size | io::error) = {
	return fprint(h, args...)? + io::write(h, ['\n'])?;
};

// Formats values for printing using the default format modifiers and writes
// them to an [[io::handle]] separated by spaces.
export fn fprint(h: io::handle, args: formattable...) (size | io::error) = {
	let mod = mods { base = strconv::base::DEC, ... };
	let n = 0z;
	for (let i = 0z; i < len(args); i += 1) {
		n += format(h, args[i], &mod)?;
		if (i != len(args) - 1) {
			n += io::write(h, [' '])?;
		};
	};
	return n;
};

// Specifies for numerical arguments when to prepend a plus or minus sign or a
// blank space.
export type negation = enum {
	NONE,
	SPACE,
	PLUS,
};

// Specifies how to align and pad an argument within a given width.
export type padding = enum {
	ALIGN_RIGHT,
	ALIGN_LEFT,
	ZEROES,
};

// Specifies how to format an argument.
export type mods = struct {
	padding:   padding,
	negation:  negation,
	width:     uint,
	precision: uint,
	base:      strconv::base,
};

type modflag = enum uint {
	NONE  = 0,
	ZERO  = 1 << 0,
	MINUS = 1 << 1,
	SPACE = 1 << 2,
	PLUS  = 1 << 3,
};

type paramindex = (uint | nextparam | void);

type nextparam = void;

// Formats text for printing and writes it to an [[io::handle]].
export fn fprintf(
	h: io::handle,
	fmt: str,
	args: field...
) (size | io::error) = {
	let n = 0z, i = 0z;
	let checkunused = true;
	let iter = strings::iter(fmt);
	for (true) {
		let r: rune = match (strings::next(&iter)) {
		case void =>
			break;
		case let r: rune =>
			yield r;
		};

		if (r == '{') {
			r = match (strings::next(&iter)) {
			case void =>
				abort("Invalid format string (unterminated '{')");
			case let r: rune =>
				yield r;
			};

			if (r == '{') {
				n += io::write(h, utf8::encoderune('{'))?;
				continue;
			};

			const idx = if (ascii::isdigit(r)) {
				strings::prev(&iter);
				checkunused = false;
				yield scan_uint(&iter): size;
			} else {
				strings::prev(&iter);
				i += 1;
				yield i - 1;
			};
			assert(idx < len(args), "Not enough parameters given");

			const arg = match (args[idx]) {
			case let arg: formattable =>
				yield arg;
			case =>
				abort("Invalid formattable");
			};

			r = match (strings::next(&iter)) {
			case void =>
				abort("Invalid format string (unterminated '{')");
			case let r: rune =>
				yield r;
			};

			let mod = &mods { ... };
			let pi: paramindex = void;
			switch (r) {
			case ':' =>
				scan_inline_modifiers(&iter, mod);
			case '%' =>
				scan_parametric_modifiers(&iter, &pi);
			case '}' => void;
			case =>
				abort("Invalid format string");
			};

			match (pi) {
			case let pi: uint =>
				checkunused = false;
				match (args[pi]) {
				case let pmod: *mods =>
					mod = pmod;
				case =>
					abort("Explicit parameter is not *fmt::mods");
				};
			case nextparam =>
				i += 1;
				match (args[i - 1]) {
				case let pmod: *mods =>
					mod = pmod;
				case =>
					abort("Implicit parameter is not *fmt::mods");
				};
			case void => void;
			};

			n += format(h, arg, mod)?;
		} else if (r == '}') {
			match (strings::next(&iter)) {
			case void =>
				abort("Invalid format string (hanging '}')");
			case let r: rune =>
				assert(r == '}', "Invalid format string (hanging '}')");
			};

			n += io::write(h, utf8::encoderune('}'))?;
		} else {
			n += io::write(h, utf8::encoderune(r))?;
		};
	};

	assert(!checkunused || i == len(args), "Too many parameters given");
	return n;
};

fn format(
	out: io::handle,
	arg: formattable,
	mod: *mods,
) (size | io::error) = {
	let z = 0z;

	let reprlen = 0z;
	if (mod.padding == padding::ALIGN_LEFT) {
		reprlen = format_raw(out, arg, mod, 0, [])?;
		z += reprlen;
	} else {
		reprlen = format_raw(io::empty, arg, mod, 0, [])?;
	};

	let padlen = 0z;
	let pad: []u8 = [];

	if (reprlen < mod.width: size) {
		padlen = mod.width: size - reprlen;
		pad = utf8::encoderune(switch (mod.padding) {
		case padding::ZEROES =>
			yield '0';
		case =>
			yield ' ';
		});
	};

	if (arg is types::numeric && mod.padding == padding::ZEROES) {
		// if padlen != 0, then inner padding will be applied
		z += format_raw(out, arg, mod, padlen, pad)?;
	}
	else {
		for (let i = 0z; i < padlen) {
			i += io::write(out, pad)?;
		};
		z += padlen;
		if (mod.padding != padding::ALIGN_LEFT) {
			z += format_raw(out, arg, mod, 0, [])?;
		};
	};

	return z;
};

fn format_raw(
	out: io::handle,
	arg: formattable,
	mod: *mods,
	padlen: size,
	pad: []u8,
) (size | io::error) = {
	match (arg) {
	case let s: str =>
		return io::write(out, strings::toutf8(s));
	case let r: rune =>
		return io::write(out, utf8::encoderune(r));
	case let b: bool =>
		return io::write(out,
			strings::toutf8(if (b) "true" else "false"));
	case let n: types::numeric =>
		const (s1, s2) = get_split_number_repr(n, mod);
		let z = io::write(out, strings::toutf8(s1))?;
		// apply inner padding if required
		for (let i = 0z; i < padlen) {
			i += io::write(out, pad)?;
		};
		z += padlen;
		z += io::write(out, strings::toutf8(s2))?;
		return z;
	case let p: uintptr =>
		const s = strconv::uptrtosb(p, mod.base);
		return io::write(out, strings::toutf8(s));
	case let v: nullable *opaque =>
		match (v) {
		case let v: *opaque =>
			let z = io::write(out, strings::toutf8("0x"))?;
			const s = strconv::uptrtosb(v: uintptr,
				strconv::base::HEX_LOWER);
			z += io::write(out, strings::toutf8(s))?;
			return z;
		case null =>
			return io::write(out, strings::toutf8("(null)"));
		};
	case void =>
		return io::write(out, strings::toutf8("void"));
	};
};

fn get_split_number_repr(n: types::numeric, mod: *mods) (str, str) = {
	const s = strconv::numerictosb(n, mod.base);
	if (is_negative(n)) {
		return (
			strings::sub(s, 0, 1),
			strings::sub(s, 1, strings::end)
		);
	} else {
		const prefix = switch (mod.negation) {
		case negation::PLUS  => yield "+";
		case negation::SPACE => yield " ";
		case negation::NONE  => yield "";
		};
		return (prefix, s);
	};
};

fn is_negative(n: types::numeric) bool = {
	match (n) {
	case let i: types::signed =>
		return math::signi(i) < 0;
	case let u: types::unsigned =>
		return false;
	case let f: types::floating =>
		return math::signf(f) < 0;
	};
};

fn scan_uint(iter: *strings::iterator) uint = {
	let copy = *iter;
	for (true) {
		let r = match (strings::next(iter)) {
		case void =>
			abort("Invalid format string (unterminated '{')");
		case let r: rune =>
			yield r;
		};

		if (!ascii::isdigit(r)) {
			strings::prev(iter);
			match (strconv::stou(strings::slice(&copy, iter))) {
			case (strconv::invalid | strconv::overflow) =>
				abort("Invalid format string (invalid index)");
			case let u: uint =>
				return u;
			};
		};
	};
	abort("unreachable");
};

fn scan_modifier_flags(iter: *strings::iterator, mod: *mods) void = {
	let flags = modflag::NONE;

	for (true) {
		let r = match (strings::next(iter)) {
		case void =>
			abort("Invalid format string (unterminated '{')");
		case let r: rune =>
			yield r;
		};

		switch (r) {
		case '0' =>
			flags |= modflag::ZERO;
		case '-' =>
			flags |= modflag::MINUS;
		case ' ' =>
			flags |= modflag::SPACE;
		case '+' =>
			flags |= modflag::PLUS;
		case =>
			strings::prev(iter);
			break;
		};
	};

	mod.padding = if (flags & modflag::MINUS != 0)
		padding::ALIGN_LEFT
	else if (flags & modflag::ZERO != 0)
		padding::ZEROES
	else
		padding::ALIGN_RIGHT;

	mod.negation = if (flags & modflag::PLUS != 0)
		negation::PLUS
	else if (flags & modflag::SPACE != 0)
		negation::SPACE
	else
		negation::NONE;
};

fn scan_modifier_width(iter: *strings::iterator, mod: *mods) void = {
	let r = match (strings::next(iter)) {
	case void =>
		abort("Invalid format string (unterminated '{')");
	case let r: rune =>
		yield r;
	};

	let is_digit = ascii::isdigit(r);
	strings::prev(iter);

	if (is_digit) {
		mod.width = scan_uint(iter);
	};
};

fn scan_modifier_precision(iter: *strings::iterator, mod: *mods) void = {
	let r = match (strings::next(iter)) {
	case void =>
		abort("Invalid format string (unterminated '{')");
	case let r: rune =>
		yield r;
	};

	if (r == '.') {
		mod.precision = scan_uint(iter);
	} else {
		strings::prev(iter);
	};
};

fn scan_modifier_base(iter: *strings::iterator, mod: *mods) void = {
	let r = match (strings::next(iter)) {
	case void =>
		abort("Invalid format string (unterminated '{')");
	case let r: rune =>
		yield r;
	};

	switch (r) {
	case 'x' =>
		mod.base = strconv::base::HEX_LOWER;
	case 'X' =>
		mod.base = strconv::base::HEX_UPPER;
	case 'o' =>
		mod.base = strconv::base::OCT;
	case 'b' =>
		mod.base = strconv::base::BIN;
	case =>
		strings::prev(iter);
	};
};

fn scan_inline_modifiers(iter: *strings::iterator, mod: *mods) void = {
	scan_modifier_flags(iter, mod);
	scan_modifier_width(iter, mod);
	scan_modifier_precision(iter, mod);
	scan_modifier_base(iter, mod);

	// eat '}'
	let terminated = match (strings::next(iter)) {
	case void =>
		yield false;
	case let r: rune =>
		yield r == '}';
	};
	assert(terminated, "Invalid format string (unterminated '{')");
};

fn scan_parameter_index(iter: *strings::iterator, pi: *paramindex) void = {
	let r = match (strings::next(iter)) {
	case void =>
		abort("Invalid format string (unterminated '{')");
	case let r: rune =>
		yield r;
	};

	let is_digit = ascii::isdigit(r);
	strings::prev(iter);
	if (is_digit) {
		*pi = scan_uint(iter);
	} else {
		*pi = nextparam;
	};
};

fn scan_parametric_modifiers(iter: *strings::iterator, pi: *paramindex) void = {
	scan_parameter_index(iter, pi);

	// eat '}'
	let terminated = match (strings::next(iter)) {
	case void =>
		yield false;
	case let r: rune =>
		yield r == '}';
	};
	assert(terminated, "Invalid format string (unterminated '{')");
};

@test fn fmt() void = {
	let buf: [1024]u8 = [0...];

	assert(bsprint(buf, "hello world") == "hello world");
	assert(bsprintf(buf, "hello world") == "hello world");
	assert(bsprintf(buf, "{} {}", "hello", "world") == "hello world");
	assert(bsprintf(buf, "{0} {1}", "hello", "world") == "hello world");
	assert(bsprintf(buf, "{0} {0}", "hello", "world") == "hello hello");
	assert(bsprintf(buf, "{1} {0} {1}", "hello", "world") == "world hello world");

	const mod = &mods { width = 7, ... };
	assert(bsprintf(buf, "{%}", "hello", mod) == "  hello");
	assert(bsprintf(buf, "{%1}", "hello", mod) == "  hello");
	assert(bsprintf(buf, "{0%1}", "hello", mod) == "  hello");
	assert(bsprintf(buf, "{0%2}", "hello", 0, mod) == "  hello");
	assert(bsprintf(buf, "{1%2}", 0, "hello", mod) == "  hello");
	assert(bsprintf(buf, "{2%0}", mod, 0, "hello") == "  hello");
	assert(bsprintf(buf, "{2%}", mod, 0, "hello") == "  hello");
	assert(bsprintf(buf, "|{1%}|{}|", mod, "hello") == "|  hello|hello|");
	assert(bsprintf(buf, "|{}|{2%}|", "hello", mod, "world") == "|hello|  world|");
	assert(bsprintf(buf, "|{%}|{%}|{%}|{%}|",
		"hello", &mods { ... },
		"world", &mods { width = 10, ... },
		123,     &mods { width = 10, padding = padding::ZEROES, ... },
		0xBEEF,  &mods { base = strconv::base::HEX, ... },
	) == "|hello|     world|0000000123|BEEF|");
	assert(bsprintf(buf, "|{%}|{%}|{0%1}|",
		"hello", &mods { ... },
		"world", &mods { ... },
	) == "|hello|world|hello|");

	assert(bsprintf(buf, "x: {:8X}", 0xBEEF) == "x:     BEEF");
	assert(bsprintf(buf, "x: {:8X}", -0xBEEF) == "x:    -BEEF");
	assert(bsprintf(buf, "x: {:+8X}", 0xBEEF) == "x:    +BEEF");
	assert(bsprintf(buf, "x: {: 8X}", 0xBEEF) == "x:     BEEF");

	assert(bsprintf(buf, "x: {:+ 8X}", 0xBEEF) == "x:    +BEEF");

	assert(bsprintf(buf, "x: {:-8X}", 0xBEEF) == "x: BEEF    ");
	assert(bsprintf(buf, "x: {:-8X}", -0xBEEF) == "x: -BEEF   ");
	assert(bsprintf(buf, "x: {:-+8X}", 0xBEEF) == "x: +BEEF   ");
	assert(bsprintf(buf, "x: {:- 8X}", 0xBEEF) == "x:  BEEF   ");

	assert(bsprintf(buf, "x: {:08x}", 0xBEEF) == "x: 0000beef");
	assert(bsprintf(buf, "x: {:08x}", -0xBEEF) == "x: -000beef");
	assert(bsprintf(buf, "x: {:+08x}", 0xBEEF) == "x: +000beef");
	assert(bsprintf(buf, "x: {: 08x}", 0xBEEF) == "x:  000beef");

	assert(bsprintf(buf, "x: {:-08X}", 0xBEEF) == "x: BEEF    ");

	assert(bsprintf(buf, "x: {:o}", 0o755) == "x: 755");
	assert(bsprintf(buf, "x: {:b}", 0b11011) == "x: 11011");

	assert(bsprintf(buf, "x: {:8}", "hello") == "x:    hello");
	assert(bsprintf(buf, "x: {:-8}", "hello") == "x: hello   ");
	assert(bsprintf(buf, "x: {:08}", "hello") == "x: 000hello");

	assert(bsprintf(buf, "{} {} {} {} {}", true, false, null, 'x', void)
		== "true false (null) x void");
};
