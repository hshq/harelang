// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fs;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
use io;
use os::exec;

export type error = !(lex::error | parse::error | io::error | module::error | exec::error | fs::error);

export fn strerror(err: error) str = {
	match (err) {
	case let err: lex::error =>
		return lex::strerror(err);
	case let err: parse::error =>
		return parse::strerror(err);
	case let err: io::error =>
		return io::strerror(err);
	case let err: module::error =>
		return module::strerror(err);
	};
};

export type format = enum {
	HARE,
	TTY,
	HTML,
};

export type context = struct {
	mctx: *module::context,
	ident: ast::ident,
	tags: []str,
	modpath: str,
	srcs: module::srcset,
	submods: []str,
	summary: summary,
	format: format,
	template: bool,
	show_undocumented: bool,
	readme: (io::file | void),
	out: io::handle,
	pager: (exec::process | void),
};

export type summary = struct {
	constants: []ast::decl,
	errors: []ast::decl,
	types: []ast::decl,
	globals: []ast::decl,
	funcs: []ast::decl,
};
