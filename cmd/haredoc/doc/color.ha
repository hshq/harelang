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
	CONSTANT,
	FUNCTION,
	GLOBAL,
	TYPEDEF,
	SECONDARY,
	KEYWORD,
	TYPE,
	ATTRIBUTE,
	OPERATOR,
	PUNCTUATION,
	STRING,
	NUMBER,
};

// Colors/Renditions with defaults; SGR parameters for ANSI escape sequences.
let COLORS: [_](str, str) = [
	("normal"      ,  "0"),
	("comment"     ,  "1"),
	("primary"     ,  "0"),
	("constant"    ,  "0"),
	("function"    ,  "0"),
	("global"      ,  "0"),
	("typedef"     ,  "0"),
	("secondary"   ,  "0"),
	("keyword"     , "94"),
	("type"        , "96"),
	("attribute"   , "33"),
	("operator"    ,  "1"),
	("punctuation" ,  "0"),
	("string"      , "91"),
	("number"      , "95"),
];

fn init_colors() void = {
	const env_colors = os::tryenv("HAREDOC_COLORS", "");

	const expr = regex::compile(`([a-z][a-z]*)=(_|[0-9;]*)`)!;
	defer regex::finish(&expr);

	const matches = regex::findall(&expr, env_colors);
	defer regex::result_freeall(matches);

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
	if (COLORS[syntax].1 == "_") {
		syntax = switch (syntax) {
		case syn::CONSTANT, syn::FUNCTION, syn::GLOBAL, syn::TYPEDEF =>
			yield if (COLORS[syn::PRIMARY].1 == "_") syn::NORMAL
				else syn::PRIMARY;
		case =>
			yield syn::NORMAL;
		};
	};
	return fmt::fprintf(h, "\x1b[0;{}m", COLORS[syntax].1)?;
};
