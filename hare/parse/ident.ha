// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use hare::ast;
use hare::lex;
use hare::lex::{ltok};
use memio;
use strings;

// Parses a single identifier, possibly with a trailing ::, i.e. 'foo::bar::'.
// Returns the identifier and whether there's a trailing ::.
export fn ident_trailing(lexer: *lex::lexer) ((ast::ident, bool) | error) = {
	let ident: []str = [];
	let trailing = false;
	const tok = want(lexer, ltok::NAME)?;
	append(ident, tok.1 as str);
	const loc = tok.2;
	let z = len(ident[0]);
	for (true) {
		match (try(lexer, ltok::DOUBLE_COLON)?) {
		case void => break;
		case => void; // Grab the next ident
		};
		z += 1;
		let name = match (try(lexer, ltok::NAME)?) {
		case let t: lex::token =>
			yield t.1 as str;
		case void =>
			trailing = true;
			break;
		};
		append(ident, name);
		z += len(name);
	};
	if (z > ast::IDENT_MAX) {
		ast::ident_free(ident: ast::ident);
		return syntaxerr(loc, "Identifier exceeds maximum length");
	};
	return (ident: ast::ident, trailing);
};

// Parses a single identifier, i.e. 'foo::bar::baz'.
export fn ident(lexer: *lex::lexer) (ast::ident | error) = {
	let ident = ident_trailing(lexer)?;
	synassert(lex::mkloc(lexer), !ident.1, "Unexpected trailing :: in ident")?;
	return ident.0;
};

// A convenience function which parses an identifier from a string, so the
// caller needn't provide a lexer instance.
export fn identstr(in: str) (ast::ident | error) = {
	let in = memio::fixed(strings::toutf8(in));
	let sc = bufio::newscanner(&in);
	defer bufio::finish(&sc);
	let lexer = lex::init(&sc, "<string>");
	let ret = ident(&lexer);
	want(&lexer, ltok::EOF)?;
	return ret;
};
