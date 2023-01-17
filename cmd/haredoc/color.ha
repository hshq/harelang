// License: GPL-3.0
// (c) 2022 Byron Torres <b@torresjrjr.com>
use ascii;
use fmt;
use io;
use os;
use regex;
use strings;

// Syntax type
type syn = enum uint {
	NORMAL,
	COMMENT,
	PRIMARY,
	SECONDARY,
	KEYWORD,
	TYPE,
	ATTRIBUTE,
	OPERATOR,
	PUNCTUATION,
	CONSTANT,
	STRING,
	NUMBER,
};

// Colors/Renditions with defaults; SGR parameters for ANSI escape sequences.
let COLORS: [_](str, str) = [
	("normal"      ,  "0"),
	("comment"     ,  "1"),
	("primary"     ,  "0"),
	("secondary"   ,  "0"),
	("keyword"     , "94"),
	("type"        , "96"),
	("attribute"   , "33"),
	("operator"    ,  "1"),
	("punctuation" ,  "0"),
	("constant"    , "91"),
	("string"      , "91"),
	("number"      , "95"),
];

fn init_colors() void = {
	const env_colors = os::tryenv("HAREDOC_COLORS", "");

	const expr = regex::compile(`([a-z][a-z]*)=(_|[0-9;]*)`)!;
	defer regex::finish(&expr);

	const matches = regex::findall(&expr, env_colors);
	defer regex::free_matches(matches);

	for (let i = 0z; i < len(matches); i += 1) :colors {
		const (k, v)  = (matches[i][1].content, matches[i][2].content);

		let idx = 0z;
		for (let j = 0z; j < len(COLORS); j += 1) {
			if (k == COLORS[j].0) {
				idx = j;
				break;
			} else if (j == len(COLORS) - 1) {
				fmt::fatalf(
					"Error parsing HAREDOC_COLORS, "
					"invalid key '{}'", k,
				);
			};
		};

		if (v == "_") {
			COLORS[idx] = if (k == "normal") (k, "0") else (k, v);
			continue;
		};
		if (v == "") {
			continue;
		};

		COLORS[idx] = (k, v);
	};
};

fn render(h: io::handle, syntax: syn) (size | io::error) = {
	switch (COLORS[syntax].1) {
	case "_" =>
		return fmt::fprintf(h, "\x1b[0;{}m", COLORS[syn::NORMAL].1)?;
	case =>
		return fmt::fprintf(h, "\x1b[0;{}m", COLORS[syntax].1)?;
	};
};
