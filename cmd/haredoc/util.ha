// License: GPL-3.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use fmt;
use io;
use strings;

// Forked from [[hare::unparse]].
fn newline(out: io::handle, indent: size) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(out, "\n")?;
	for (let i = 0z; i < indent; i += 1) {
		n += fmt::fprint(out, "\t")?;
	};
	return n;
};

fn multiline_comment(s: str) bool =
	strings::byteindex(s, '\n') as size != len(s) - 1;
