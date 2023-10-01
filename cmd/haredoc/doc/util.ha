// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fmt;
use fs;
use hare::module;
use io;
use memio;
use os;
use sort;
use sort::cmp;
use strings;

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

export fn submodules(path: str) ([]str | error) = {
	let submodules: []str = [];
	let it = os::iter(path)?;
	defer fs::finish(it);
	for (true) match (module::next(it)) {
	case void =>
		break;
	case let d: fs::dirent =>
		append(submodules, strings::dup(d.name));
	};
	sort::sort(submodules, size(str), &cmp::strs);
	return submodules;
};
