// License: MPL-2.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use fmt;
use io;
use strings;
use strio;

// Dumps a [[value]] into an [[io::handle]] as a string without any additional
// formatting.
export fn dump(out: io::handle, val: value) (size | io::error) = {
	let z = 0z;
	match (val) {
	case let v: (f64 | bool) =>
		z += fmt::fprint(out, v)?;
	case let s: str =>
		z += fmt::fprint(out, `"`)?;
		let it = strings::iter(s);
		for (true) match (strings::next(&it)) {
		case void =>
			break;
		case let r: rune =>
			switch (r) {
			case '\b' =>
				z += fmt::fprint(out, `\b`)?;
			case '\f' =>
				z += fmt::fprint(out, `\f`)?;
			case '\n' =>
				z += fmt::fprint(out, `\n`)?;
			case '\r' =>
				z += fmt::fprint(out, `\r`)?;
			case '\t' =>
				z += fmt::fprint(out, `\t`)?;
			case '\"' =>
				z += fmt::fprint(out, `\"`)?;
			case '\\' =>
				z += fmt::fprint(out, `\\`)?;
			case =>
				if (iscntrl(r)) {
					z += fmt::fprintf(out, `\u{:04x}`,
						r: u32)?;
				} else {
					z += fmt::fprint(out, r)?;
				};
			};
		};
		z += fmt::fprint(out, `"`)?;
	case _null =>
		z += fmt::fprint(out, "null")?;
	case let a: []value =>
		z += fmt::fprint(out, "[")?;
		for (let i = 0z; i < len(a); i += 1) {
			z += dump(out, a[i])?;
			if (i < len(a) - 1) {
				z += fmt::fprint(out, ",")?;
			};
		};
		z += fmt::fprint(out, "]")?;
	case let o: object =>
		z += fmt::fprint(out, "{")?;
		let comma = false;
		let it = iter(&o);
		for (true) match (next(&it)) {
		case void => break;
		case let pair: (const str, const *value) =>
			if (comma) {
				z += fmt::fprint(out, ",")?;
			};
			comma = true;
			z += dump(out, pair.0)?;
			z += fmt::fprint(out, ":")?;
			z += dump(out, *pair.1)?;
		};
		z += fmt::fprint(out, "}")?;
	};
	return z;
};

// Dumps a [[value]] into a string without any additional formatting. The caller
// must free the return value.
export fn dumpstr(val: value) str = {
	let s = strio::dynamic();
	dump(&s, val)!;
	return strio::string(&s);
};
