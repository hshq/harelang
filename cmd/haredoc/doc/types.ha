// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use fmt;
use fs;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
use hare::parse::doc;
use io;
use os::exec;

export type haredoc_colors_error = !str;

export type error = !(lex::error | parse::error | doc::error | io::error |
	module::error | exec::error | fs::error | haredoc_colors_error |
	utf8::invalid);

export fn strerror(err: error) str = {
	match (err) {
	case let err: lex::error =>
		return lex::strerror(err);
	case let err: parse::error =>
		return parse::strerror(err);
	case let err: doc::error =>
		return doc::strerror(err);
	case let err: io::error =>
		return io::strerror(err);
	case let err: module::error =>
		return module::strerror(err);
	case let err: exec::error =>
		return exec::strerror(err);
	case let err: fs::error =>
		return fs::strerror(err);
	case let err: utf8::invalid =>
		return utf8::strerror(err);
	case let err: haredoc_colors_error =>
		def ERRMSG = "Error parsing HAREDOC_COLORS: invalid key";
		if (len(err) == 0) {
			return ERRMSG;
		};
		static let buf: [len(ERRMSG) + 64 + 3]u8 = [0...];
		return fmt::bsprintf(buf, "{} '{}'", ERRMSG, err);
	};
};

export type context = struct {
	mctx: *module::context,
	ident: ast::ident,
	tags: []str,
	ambiguous: bool,
	srcs: module::srcset,
	submods: []str,
	summary: summary,
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

export fn finish_summary(s: summary) void = {
	for (let c .. s.constants) {
		free(c.decl as []ast::decl_const);
	};
	free(s.constants);

	for (let e .. s.errors) {
		free(e.decl as []ast::decl_type);
	};
	free(s.errors);

	for (let t .. s.types) {
		free(t.decl as []ast::decl_type);
	};
	free(s.types);

	for (let g .. s.globals) {
		free(g.decl as []ast::decl_global);
	};
	free(s.globals);

	free(s.funcs);
};
