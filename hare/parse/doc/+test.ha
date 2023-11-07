// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use hare::lex;
use hare::unparse;
use memio;
use os;
use strings;

fn assert_doc_eq(a: doc, b: doc) void = {
	assert(len(a) == len(b));
	for (let i = 0z; i < len(a); i += 1) {
		match (a[i]) {
		case let a: paragraph =>
			const b = b[i] as paragraph;
			assert_paragraph_eq(a, b);
		case let a: list =>
			const b = b[i] as list;
			assert(len(a) == len(b));
			for (let i = 0z; i < len(a); i += 1) {
				assert_paragraph_eq(a[i], b[i]);
			};
		case let a: code_sample =>
			const b = b[i] as code_sample;
			if (a != b) {
				fmt::errorfln("=== wanted code sample\n{}", b)!;
				fmt::errorfln("=== got code sample\n{}", a)!;
				abort();
			};
		};
	};
};

fn assert_paragraph_eq(a: paragraph, b: paragraph) void = {
	fmt::errorln(len(a), len(b))!;
	assert(len(a) == len(b));
	for (let i = 0z; i < len(a); i += 1) {
		match (a[i]) {
		case let a: str =>
			const b = b[i] as str;
			if (a != b) {
				fmt::errorfln("=== wanted text\n{}", b)!;
				fmt::errorfln("=== got text\n{}", a)!;
				abort();
			};
		case let a: decl_ref =>
			const b = b[i] as decl_ref;
			if (!ast::ident_eq(a, b)) {
				fmt::error("=== wanted decl_ref ")!;
				unparse::ident(os::stderr, b)!;
				fmt::error("\n=== got decl_ref ")!;
				unparse::ident(os::stderr, a)!;
				fmt::errorln()!;
				abort();
			};
		case let a: mod_ref =>
			const b = b[i] as mod_ref;
			if (!ast::ident_eq(a, b)) {
				fmt::error("=== wanted mod_ref ")!;
				unparse::ident(os::stderr, b)!;
				fmt::error("\n=== got mod_ref ")!;
				unparse::ident(os::stderr, a)!;
				fmt::errorln()!;
				abort();
			};
		};
	};
};

@test fn doc() void = {
	// if you have some way in your editor to distinguish tabs from spaces
	// you're gonna want to use it here
	let in = memio::fixed(strings::toutf8(
` Blablabla asdfghjkl
 qwerty[[uiop::]] zxcvbnm

 new paragraph
 - list starting immediately after paragraph
 - another list item
 - yet another
   but this one
   spans multiple lines
 -no leading space
still multiple lines

 	code sample
 	line 2
	no leading space


 	continuing the same code sample
 		  	indentation is preserved
 		  	as   well as multiple     spaces
  	this is now a paragraph because of the [[leading::spaces]]

 - list starting [[after]] [[empty::line::]]

 but with only [one item]]
 -
	code sample starting immediately after list with one empty item`
	));

	const doc = parse(&in, lex::location { ... })!;
	defer freeall(doc);

	assert_doc_eq(doc, [
		[
			"Blablabla asdfghjkl qwerty",
			["uiop"]: mod_ref,
			" zxcvbnm",
		]: paragraph,

		["new paragraph"]: paragraph,

		[
			["list starting immediately after paragraph"],
			["another list item"],
			["yet another but this one spans multiple lines"],
			["no leading space still multiple lines"],
		]: list,

		`code sample
line 2
no leading space


continuing the same code sample
	  	indentation is preserved
	  	as   well as multiple     spaces`: code_sample,

	  	[
	  		" this is now a paragraph because of the ",
	  		["leading", "spaces"]: decl_ref,
		]: paragraph,

		[
			[
				"list starting ",
				["after"]: decl_ref,
				" ",
				["empty", "line"]: mod_ref,
			],
		]: list,

		["but with only [one item]]"]: paragraph,

		[[]]: list,

		"code sample starting immediately after list with one empty item": code_sample,
	]);
};

@test fn invalid_ref() void = {
	const tests: [_](str, uint, uint) = [
		("[[abort]]", 1, 3),
		("[[::foo]]", 1, 3),
		("[[]]", 1, 3),
		("[[foo]", 1, 7),
		("   \t\n a\n asdf\t [[]]", 3, 12),
	];
	for (let i = 0u; i < len(tests): uint; i += 1) {
		let in = memio::fixed(strings::toutf8(tests[i].0));
		fmt::errorln(tests[i].0)!;
		const err = parse(&in, lex::location {
			path = "<test>",
			line = i + 1,
			col = i + 1,
		}) as lex::syntax;
		assert(err.0.path == "<test>");
		assert(err.0.line == i + tests[i].1);
		assert(err.0.col == i + tests[i].2);
	};
};
