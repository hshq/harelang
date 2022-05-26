// License: GPL-3.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use fmt;
use io;
use strings;
use strio;

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

fn trim_comment(s: str) str = {
	let trimmed = strio::dynamic();
	let tok = strings::tokenize(s, "\n");
	for (true) {
		const line = match (strings::next_token(&tok)) {
		case void =>
			break;
		case let line: str =>
			yield line;
		};
		strio::concat(&trimmed, strings::trimprefix(line, " "), "\n")!;
	};
	return strings::dup(strio::string(&trimmed));
};
