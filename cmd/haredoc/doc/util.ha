// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fmt;
use fs;
use hare::module;
use io;
use memio;
use os;
use path;
use sort;
use sort::cmp;
use strings;

let firstline: bool = true;

fn trim_comment(s: str) str = {
	let trimmed = memio::dynamic();
	let tok = strings::tokenize(s, "\n");
	for (true) {
		const line = match (strings::next_token(&tok)) {
		case void =>
			break;
		case let line: str =>
			yield line;
		};
		memio::concat(&trimmed, strings::trimprefix(line, " "), "\n")!;
	};
	return strings::dup(memio::string(&trimmed)!);
};

export fn submodules(path: str, show_undocumented: bool) ([]str | error) = {
	let submodules: []str = [];
	let it = os::iter(path)?;
	defer fs::finish(it);
	let pathbuf = path::init(path)!;
	for (true) match (module::next(it)?) {
	case let d: fs::dirent =>
		path::set(&pathbuf, path, d.name, "README")!;
		if (show_undocumented || os::exists(path::string(&pathbuf))) {
			append(submodules, strings::dup(d.name));
		};
	case void =>
		break;
	};
	sort::sort(submodules, size(str), &cmp::strs);
	return submodules;
};
