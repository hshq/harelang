// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::ast;
use io;

// A user-supplied function which writes unparsed Hare source code to a handle,
// optionally including extra stylistic features. The function is expected to
// write to, at the minimum, write the provided string to ctx.out, and update
// ctx.linelen based on how much data was written.
//
// [[syn_nowrap]] and [[syn_wrap]] are provided for when no additional styling
// is desired.
export type synfunc = fn(
	ctx: *context,
	s: str,
	kind: synkind,
) (size | io::error);

// The kind of thing being unparsed.
export type synkind = enum {
	IDENT,
	COMMENT,
	CONSTANT,
	FUNCTION,
	GLOBAL,
	TYPEDEF,
	IMPORT_ALIAS,
	SECONDARY,
	KEYWORD,
	TYPE,
	ATTRIBUTE,
	OPERATOR,
	PUNCTUATION,
	RUNE_STRING,
	NUMBER,
	LABEL,
};

// Context about the unparsing state supplied to a [[synfunc]]. The linelen and
// indent fields may be mutated.
export type context = struct {
	out: io::handle,
	stack: nullable *stack,
	linelen: size,
	indent: size,
};

// A linked list of AST nodes currently being unparsed.
export type stack = struct {
	cur: (*ast::decl | *ast::expr | *ast::_type | *ast::import),
	up: nullable *stack,
	extra: nullable *opaque,
};

// A [[synfunc]] implementation which unparses without additional styling, and
// without wrapping any long lines.
export fn syn_nowrap(
	ctx: *context,
	s: str,
	kind: synkind,
) (size | io::error) = {
	const z = fmt::fprint(ctx.out, s)?;
	ctx.linelen += z;
	return z;
};

type syn_wrap_extra = enum {
	NONE,
	MULTILINE_FN_PARAM,
	MULTILINE_FN_OTHER,
	MULTILINE_TAGGED_OR_TUPLE,
};

// A [[synfunc]] implementation which unparses without additional styling, but
// which wraps some long lines at 80 columns, in accordance with the style
// guide.
export fn syn_wrap(ctx: *context, s: str, kind: synkind) (size | io::error) = {
	let extra = :extra {
		let st = match (ctx.stack) {
		case let st: *stack =>
			yield st;
		case null =>
			yield :extra, &syn_wrap_extra::NONE;
		};

		match (st.extra) {
		case let p: *opaque =>
			yield :extra, p: *syn_wrap_extra;
		case null =>
			match (st.up) {
			case let st: *stack =>
				match (st.extra) {
				case let p: *opaque =>
					const p = p: *syn_wrap_extra;
					if (*p == syn_wrap_extra::MULTILINE_FN_PARAM) {
						yield :extra, p;
					};
				case null => void;
				};
			case null => void;
			};
		};

		if (s == "(") match (st.cur) {
		case let t: *ast::_type =>
			match (t.repr) {
			case ast::func_type => void;
			case =>
				yield :extra, &syn_wrap_extra::NONE;
			};

			let z = _type(io::empty, &syn_nowrap, t)!;
			if (ctx.linelen + z < 80) yield;
			st.extra = alloc(syn_wrap_extra::MULTILINE_FN_PARAM);
			z = fmt::fprintln(ctx.out, s)?;
			ctx.linelen = 0;
			ctx.indent += 1;
			return z;
		case =>
			yield :extra, &syn_wrap_extra::NONE;
		};

		// use 72 as max linelen instead of 80 to give a bit of leeway.
		// XXX: this probably could be made more accurate
		if (ctx.linelen < 72 || (s != "," && s != "|")) {
			yield :extra, &syn_wrap_extra::NONE;
		};

		const t = match (st.cur) {
		case let t: *ast::_type =>
			yield t;
		case =>
			yield :extra, &syn_wrap_extra::NONE;
		};

		match (t.repr) {
		case (ast::tagged_type | ast::tuple_type) => void;
		case =>
			yield :extra, &syn_wrap_extra::NONE;
		};

		st.extra = alloc(syn_wrap_extra::MULTILINE_TAGGED_OR_TUPLE);
		let z = fmt::fprintln(ctx.out, s)?;
		ctx.indent += 1;
		ctx.linelen = ctx.indent * 8;
		for (let i = 0z; i < ctx.indent; i += 1) {
			z += fmt::fprint(ctx.out, "\t")?;
		};
		return z;
	};

	let z = 0z;

	switch (*extra) {
	case syn_wrap_extra::NONE => void;
	case syn_wrap_extra::MULTILINE_FN_PARAM =>
		switch (s) {
		case ")" =>
			match (ctx.stack) {
			case let st: *stack =>
				free(st.extra);
				st.extra = null;
			case null => void;
			};
			ctx.indent -= 1;
		case "..." =>
			match (ctx.stack) {
			case let st: *stack =>
				free(st.extra);
				st.extra = null;
			case null => void;
			};
			for (let i = 0z; i < ctx.indent; i += 1) {
				z += fmt::fprint(ctx.out, "\t")?;
			};
			z += fmt::fprintln(ctx.out, s)?;
			ctx.indent -= 1;
			ctx.linelen = 0;
			return z;
		case =>
			*extra = syn_wrap_extra::MULTILINE_FN_OTHER;
			ctx.linelen = ctx.indent * 8;
			for (let i = 0z; i < ctx.indent; i += 1) {
				z += fmt::fprint(ctx.out, "\t")?;
			};
		};
	case syn_wrap_extra::MULTILINE_FN_OTHER =>
		switch (s) {
		case ")" =>
			match (ctx.stack) {
			case let st: *stack =>
				free(st.extra);
				st.extra = null;
			case null => void;
			};
			ctx.indent -= 1;
			ctx.linelen = ctx.indent * 8;
			z += fmt::fprintln(ctx.out, ",")?;
			for (let i = 0z; i < ctx.indent; i += 1) {
				z += fmt::fprint(ctx.out, "\t")?;
			};
		case ",", "..." =>
			*extra = syn_wrap_extra::MULTILINE_FN_PARAM;
			ctx.linelen = 0;
			return fmt::fprintln(ctx.out, s)?;
		case => void;
		};
	case syn_wrap_extra::MULTILINE_TAGGED_OR_TUPLE =>
		switch (s) {
		case ")" =>
			let st = ctx.stack as *stack;
			free(st.extra);
			st.extra = null;
			ctx.indent -= 1;
		case ",", "|" =>
			if (ctx.linelen < 72) yield;
			z += fmt::fprintln(ctx.out, s)?;
			ctx.linelen = ctx.indent * 8;
			for (let i = 0z; i < ctx.indent; i += 1) {
				z += fmt::fprint(ctx.out, "\t")?;
			};
			return z;
		case => void;
		};
	};

	z += syn_nowrap(ctx, s, kind)?;
	return z;
};
