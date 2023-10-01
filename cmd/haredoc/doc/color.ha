// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use ascii;
use hare::unparse;
use io;
use os;
use regex;
use strings;

// Colors/Renditions with defaults; SGR parameters for ANSI escape sequences.
let colors: [_]str = [
	"0",  // ident
	"1",  // comment
	"0",  // constant
	"0",  // function
	"0",  // global
	"0",  // typedef
	"0",  // import_alias
	"0",  // secondary
	"94", // keyword
	"96", // type
	"33", // attribute
	"1",  // operator
	"0",  // punctuation
	"91", // rune_string
	"95", // number
	"0",  // label
];

let normal_color = "0";
let primary_color = "0";

fn init_colors() (void | error) = {
	const env_colors = os::tryenv("HAREDOC_COLORS", "");

	const expr = regex::compile(`([a-z_]+)=(_|[0-9;]*)`)!;
	defer regex::finish(&expr);

	const matches = regex::findall(&expr, env_colors);
	defer regex::result_freeall(matches);

	for (let i = 0z; i < len(matches); i += 1) :colors {
		let (k, v)  = (matches[i][1].content, matches[i][2].content);
		if (v == "") {
			continue;
		};

		let idx = 0z;
		let out: *str = switch (k) {
		case "ident" =>
			yield &colors[unparse::synkind::IDENT];
		case "comment" =>
			yield &colors[unparse::synkind::COMMENT];
		case "constant" =>
			yield &colors[unparse::synkind::CONSTANT];
		case "function" =>
			yield &colors[unparse::synkind::FUNCTION];
		case "global" =>
			yield &colors[unparse::synkind::GLOBAL];
		case "typedef" =>
			yield &colors[unparse::synkind::TYPEDEF];
		case "import_alias" =>
			yield &colors[unparse::synkind::IMPORT_ALIAS];
		case "secondary" =>
			yield &colors[unparse::synkind::SECONDARY];
		case "keyword" =>
			yield &colors[unparse::synkind::KEYWORD];
		case "type" =>
			yield &colors[unparse::synkind::TYPE];
		case "attribute" =>
			yield &colors[unparse::synkind::ATTRIBUTE];
		case "operator" =>
			yield &colors[unparse::synkind::OPERATOR];
		case "punctuation" =>
			yield &colors[unparse::synkind::PUNCTUATION];
		case "rune_string" =>
			yield &colors[unparse::synkind::RUNE_STRING];
		case "number" =>
			yield &colors[unparse::synkind::NUMBER];
		case "label" =>
			yield &colors[unparse::synkind::LABEL];
		case "normal" =>
			yield &normal_color;
		case "primary" =>
			yield &primary_color;
		case =>
			return k: haredoc_colors_error;
		};

		*out = if (v == "_" && k != "normal") "0" else v;
	};
};

fn color(kind: unparse::synkind) str = {
	if (colors[kind] != "_") {
		return colors[kind];
	};
	switch (kind) {
	case unparse::synkind::CONSTANT,
		unparse::synkind::FUNCTION,
		unparse::synkind::GLOBAL,
		unparse::synkind::TYPEDEF =>
		return primary_color;
	case =>
		return normal_color;
	};
};
