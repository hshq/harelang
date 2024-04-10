// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use io;
use math;
use strconv;
use strings;
use types;

// Formats values for printing using the default format modifiers and writes
// them to an [[io::handle]] separated by spaces.
export fn fprint(h: io::handle, args: formattable...) (io::error | size) = {
	let mod = mods { ... };
	let n = 0z;
	for (let i = 0z; i < len(args); i += 1) {
		n += format(h, args[i], &mod)?;
		if (i != len(args) - 1) {
			n += format(h, " ", &mod)?;
		};
	};
	return n;
};

// Formats text for printing and writes it to an [[io::handle]].
export fn fprintf(
	h: io::handle,
	fmt: str,
	args: field...
) (io::error | size) = {
	let n = 0z, i = 0z;
	let it = iter(fmt, args);
	for (true) match (next(&it)) {
	case done => break;
	case let s: str =>
		n += format(h, s, &mods { ... })?;
	case let f: (formattable, mods) =>
		n += format(h, f.0, &f.1)?;
	};

	assert(!it.checkunused || it.idx == len(args), "Too many parameters given");
	return n;
};

fn format(
	out: io::handle,
	arg: formattable,
	mod: *mods,
) (size | io::error) = {
	let start = 0z;
	// guaranteed not to have starting padding in either of these cases
	// saves the extra format_raw()
	if (mod.width > 0 && mod.alignment != alignment::LEFT) {
		let width = format_raw(io::empty, arg, mod)?;
		let pad = if (width > mod.width) 0z else mod.width - width;

		switch (mod.alignment) {
		case alignment::LEFT => abort();
		case alignment::CENTER => start = (pad + 1) / 2;
		case alignment::RIGHT => start = pad;
		};
	};

	let z = 0z;
	for (z < start) {
		z += io::write(out, utf8::encoderune(mod.pad))?;
	};
	z += format_raw(out, arg, mod)?;
	for (z < mod.width) {
		z += io::write(out, utf8::encoderune(mod.pad))?;
	};

	return z;
};

fn format_raw(
	out: io::handle,
	arg: formattable,
	mod: *mods,
) (size | io::error) = match (arg) {
case void =>
	return io::write(out, strings::toutf8("void"));
case let r: rune =>
	return io::write(out, utf8::encoderune(r));
case let s: str =>
	if (mod.prec > 0 && mod.prec < len(s)) {
		s = strings::sub(s, 0, mod.prec);
	};
	return io::write(out, strings::toutf8(s));
case let b: bool =>
	return io::write(out, strings::toutf8(if (b) "true" else "false"));
case let p: uintptr =>
	const s = strconv::uptrtos(p, mod.base);
	return io::write(out, strings::toutf8(s));
case let v: nullable *opaque =>
	match (v) {
	case let v: *opaque =>
		let z = io::write(out, strings::toutf8("0x"))?;
		const s = strconv::uptrtos(v: uintptr, strconv::base::HEX_LOWER);
		z += io::write(out, strings::toutf8(s))?;
		return z;
	case null =>
		return io::write(out, strings::toutf8("(null)"));
	};
case let f: types::floating =>
	assert(mod.base == strconv::base::DEFAULT
		|| mod.base == strconv::base::DEC); // TODO
	assert(mod.prec <= types::UINT_MAX);
	// TODO: mod.prec should be (size | void) but that needs @default
	return strconv::fftosf(out, f, mod.ffmt,
		if (mod.prec != 0) mod.prec: uint else void, mod.fflags)?;
case let i: types::integer =>
	let neg = match (i) {
	case types::unsigned =>
		yield false;
	case let s: types::signed =>
		i = math::absi(s);
		yield math::signi(s) < 0;
	};
	let sign = if (neg) "-" else {
		yield switch (mod.neg) {
		case neg::PLUS => yield "+";
		case neg::SPACE => yield " ";
		case neg::NONE => yield "";
		};
	};

	let i = strconv::integertos(i, mod.base);
	let pad = if (mod.prec < len(sign) + len(i)) {
		yield 0z;
	} else {
		yield mod.prec - len(sign) - len(i);
	};

	let z = io::write(out, strings::toutf8(sign))?;
	for (let i = 0z; i < pad) {
		i += io::write(out, ['0'])?;
	};
	z += pad;
	return z + io::write(out, strings::toutf8(i))?;
};
