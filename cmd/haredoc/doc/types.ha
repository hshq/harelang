// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fmt;
use fs;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
use io;
use os::exec;

export type haredoc_colors_error = !str;

export type error = !(lex::error | parse::error | io::error | module::error |
	exec::error | fs::error | haredoc_colors_error);

def HAREDOC_COLORS_ERROR_MSG = "Error parsing HAREDOC_COLORS: invalid key";

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
	case let err: exec::error =>
		return exec::strerror(err);
	case let err: fs::error =>
		return fs::strerror(err);
	case let err: haredoc_colors_error =>
		let buf: [128]u8 = [0...];
		if (len(HAREDOC_COLORS_ERROR_MSG) + len(err) + 3 > len(buf)) {
			return HAREDOC_COLORS_ERROR_MSG;
		};
		return fmt::bsprintf(buf, "{} '{}'",
			HAREDOC_COLORS_ERROR_MSG, err);
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
