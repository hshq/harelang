// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use hare::ast;
use hare::lex;
use hare::lex::{ltok};
use io;
use io::{mode};
use memio;
use strings;

fn ident_test(in: str, expected: ast::ident, extra: ltok...) void = {
	let buf = memio::fixed(strings::toutf8(in));
	let sc = bufio::newscanner(&buf);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, "<test>");

	match (ident(&lexer)) {
	case let id: ast::ident =>
		defer ast::ident_free(id);
		assert(ast::ident_eq(id, expected));
	case lex::syntax =>
		assert(len(expected) == 0);
	case error => abort();
	};

	for (let i = 0z; i < len(extra); i += 1) {
		let tok = lex::lex(&lexer)!;
		defer if (tok.1 is str) free(tok.1 as str);
		assert(tok.0 == extra[i]);
	};
	let tok = lex::lex(&lexer)!;
	defer if (tok.1 is str) free(tok.1 as str);
	assert(tok.0 == ltok::EOF);
};

@test fn ident() void = {
	ident_test(";", [], ltok::SEMICOLON);
	ident_test("foo", ["foo"]);
	ident_test("foo::bar", ["foo", "bar"]);
	ident_test("foo::bar::baz", ["foo", "bar", "baz"]);
	ident_test("foo::bar;", ["foo", "bar"], ltok::SEMICOLON);

	// identifier exceeds maximum length
	let buf: [ast::IDENT_MAX / 2 + ast::IDENT_MAX + 3]u8 = [0...];
	let buf = buf[..0];
	static append(buf, 'a');
	for (let i = 0z; i < ast::IDENT_MAX / 2; i += 1) {
		static append(buf, [':', ':', 'a']...);
	};
	ident_test(strings::fromutf8(buf)!,
		["a"...]: [ast::IDENT_MAX / 2 + 1]str);
	static append(buf, [':', ':', 'a']...);
	ident_test(strings::fromutf8(buf)!, []);
};
