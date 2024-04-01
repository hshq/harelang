// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use hare::ast;
use hare::lex;
use hare::lex::{ltok};
use strings;

fn attr_symbol(lexer: *lex::lexer) (str | error) = {
	want(lexer, ltok::LPAREN)?;
	let t = want(lexer, ltok::LIT_STR)?;
	let s = t.1 as str;
	let d = strings::iter(s);
	match (strings::next(&d)) {
	case done => void;
	case let r: rune =>
		synassert(t.2, ascii::isalpha(r) || r == '.'
			|| r == '_', "Invalid symbol")?;
	};
	for (let r => strings::next(&d)) {
		synassert(t.2, ascii::isalnum(r) || r == '$'
			|| r == '.' || r == '_', "Invalid symbol")?;
	};
	want(lexer, ltok::RPAREN)?;
	return s;
};

// Parses a command-line definition
export fn define(lexer: *lex::lexer) (ast::decl_const | error) = {
	const ident = ident(lexer)?;
	const _type: nullable *ast::_type = match (try(lexer, ltok::COLON)?) {
	case lex::token => yield alloc(_type(lexer)?);
	case void => yield null;
	};
	want(lexer, ltok::EQUAL)?;
	const init: *ast::expr = alloc(expr(lexer)?);
	return ast::decl_const {
		ident = ident,
		_type = _type,
		init = init,
	};
};

fn decl_const(
	lexer: *lex::lexer,
	tok: ltok,
) ([]ast::decl_const | error) = {
	let decl: []ast::decl_const = [];
	for (true) {
		append(decl, define(lexer)?);

		if (try(lexer, ltok::COMMA)? is void) {
			break;
		};
	};
	return decl;

};

fn decl_global(
	lexer: *lex::lexer,
	tok: ltok,
) ([]ast::decl_global | error) = {
	let decl: []ast::decl_global = [];
	for (true) {
		const (symbol, threadlocal) = match (try(lexer,
			ltok::ATTR_SYMBOL, ltok::ATTR_THREADLOCAL)?) {
		case void =>
			yield ("", false);
		case let t: lex::token =>
			yield if (t.0 == ltok::ATTR_SYMBOL) {
				yield (attr_symbol(lexer)?, false);
			} else {
				yield ("", true);
			};
		};
		const ident = ident(lexer)?;
		const _type: nullable *ast::_type =
			match (try(lexer, ltok::COLON)?) {
			case lex::token =>
				yield alloc(_type(lexer)?);
			case void =>
				yield null;
			};
		const init: nullable *ast::expr =
			match (try(lexer, ltok::EQUAL)?) {
			case lex::token =>
				yield alloc(expr(lexer)?);
			case void =>
				yield null;
			};
		const btok = try(lexer, ltok::COMMA)?;
		append(decl, ast::decl_global {
			is_const = tok == ltok::CONST,
			is_threadlocal = threadlocal,
			symbol = symbol,
			ident = ident,
			_type = _type,
			init = init,
		});
		if (btok is void) {
			break;
		};
	};
	return decl;
};

fn decl_type(lexer: *lex::lexer) ([]ast::decl_type | error) = {
	let decl: []ast::decl_type = [];
	for (true) {
		let ident = ident(lexer)?;
		want(lexer, ltok::EQUAL)?;
		let _type = _type(lexer)?;
		let btok = try(lexer, ltok::COMMA)?;
		append(decl, ast::decl_type {
			ident = ident,
			_type = alloc(_type),
		});
		if (btok is void) {
			break;
		};
	};
	return decl;
};

fn decl_func(lexer: *lex::lexer) (ast::decl_func | error) = {
	let attr = ast::fndecl_attr::NONE, sym = "";
	const attrs = [
		ltok::ATTR_FINI, ltok::ATTR_INIT, ltok::ATTR_TEST,
		ltok::ATTR_SYMBOL
	];
	for (true) match (try(lexer, attrs...)?) {
	case void =>
		break;
	case let t: lex::token =>
		synassert(t.2, t.0 == ltok::ATTR_SYMBOL || attr == 0,
			"Only one of @init, @fini, or @test may be provided")?;
		switch (t.0) {
		case ltok::ATTR_FINI =>
			attr = ast::fndecl_attr::FINI;
		case ltok::ATTR_INIT =>
			attr = ast::fndecl_attr::INIT;
		case ltok::ATTR_TEST =>
			attr = ast::fndecl_attr::TEST;
		case ltok::ATTR_SYMBOL =>
			sym = attr_symbol(lexer)?;
		case =>
			abort("unreachable");
		};
	};

	want(lexer, ltok::FN)?;
	let ident_loc = lex::mkloc(lexer);
	let ident = ident(lexer)?;
	let proto_start = lex::mkloc(lexer);
	let prototype = prototype(lexer)?;
	let proto_end = lex::prevloc(lexer);

	let tok = want(lexer, ltok::EQUAL, ltok::SEMICOLON)?;
	let body = switch (tok.0) {
	case ltok::EQUAL =>
		for (let param &.. prototype.params) {
			synassert(param.loc,
				len(param.name) > 0,
				"Expected parameter name in function declaration")?;
		};
		yield alloc(expr(lexer)?);
	case ltok::SEMICOLON =>
		lex::unlex(lexer, tok);
		yield null;
	case => abort(); // unreachable
	};

	return ast::decl_func {
		symbol = sym,
		ident = ident,
		prototype = alloc(ast::_type {
			start = proto_start,
			end = proto_end,
			flags = 0,
			repr = prototype,
		}),
		body = body,
		attrs = attr,
	};
};

// Parses a declaration.
export fn decl(lexer: *lex::lexer) (ast::decl | error) = {
	const start = lex::mkloc(lexer);
	let comment = "";
	if (try(lexer, ltok::STATIC)? is lex::token) {
		comment = strings::dup(lex::comment(lexer));
		let expr = assert_expr(lexer, true)?;
		want(lexer, ltok::SEMICOLON)?;
		return ast::decl {
			exported = false,
			start = start,
			end = expr.end,
			decl = expr.expr as ast::assert_expr,
			docs = comment,
		};
	};
	let exported = match (try(lexer, ltok::EXPORT)?) {
	case void =>
		yield false;
	case lex::token =>
		comment = strings::dup(lex::comment(lexer));
		yield true;
	};
	const toks = [ltok::CONST, ltok::LET, ltok::DEF, ltok::TYPE];
	const next = try(lexer, toks...)?;
	if (comment == "") {
		comment = strings::dup(lex::comment(lexer));
	};
	let decl = match (next) {
	case void =>
		yield decl_func(lexer)?;
	case let t: lex::token =>
		yield switch (t.0) {
		case ltok::TYPE =>
			yield decl_type(lexer)?;
		case ltok::LET, ltok::CONST =>
			yield decl_global(lexer, t.0)?;
		case ltok::DEF =>
			yield decl_const(lexer, t.0)?;
		case => abort();
		};
	};
	want(lexer, ltok::SEMICOLON)?;
	return ast::decl {
		exported = exported,
		start = start,
		end = lex::mkloc(lexer),
		decl = decl,
		docs = comment,
	};
};

// Parses the declarations for a sub-unit.
export fn decls(lexer: *lex::lexer) ([]ast::decl | error) = {
	let decls: []ast::decl = [];
	for (true) {
		if (peek(lexer, ltok::EOF)? is lex::token) break;
		append(decls, decl(lexer)?);
	};
	return decls;
};
