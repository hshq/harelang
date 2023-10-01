// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use hare::ast;
use hare::module;
use hare::unparse;
use io;
use os;
use strings;

// Formats output as Hare source code (prototypes)
export fn emit_hare(ctx: *context) (void | error) = {
	const summary = ctx.summary;

	let first = true;
	match (ctx.readme) {
	case let readme: io::file =>
		first = false;
		for (true) {
			match (bufio::read_line(readme)?) {
			case io::EOF =>
				break;
			case let b: []u8 =>
				fmt::fprintfln(ctx.out,
					"// {}", strings::fromutf8(b)!)?;
				free(b);
			};
		};
	case void => void;
	};

	emit_submodules_hare(ctx)?;

	// XXX: Should we emit the dependencies, too?
	for (let i = 0z; i < len(summary.types); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.types[i])?;
	};
	for (let i = 0z; i < len(summary.constants); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.constants[i])?;
	};
	for (let i = 0z; i < len(summary.errors); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.errors[i])?;
	};
	for (let i = 0z; i < len(summary.globals); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.globals[i])?;
	};
	for (let i = 0z; i < len(summary.funcs); i += 1) {
		if (!first) {
			fmt::fprintln(ctx.out)?;
		};
		first = false;
		details_hare(ctx, summary.funcs[i])?;
	};
};

fn emit_submodules_hare(ctx: *context) (void | error) = {
	if (len(ctx.submods) != 0) {
		fmt::fprintln(ctx.out)?;
		if (len(ctx.ident) == 0) {
			fmt::fprintln(ctx.out, "// Modules")?;
		} else {
			fmt::fprintln(ctx.out, "// Submodules")?;
		};
		for (let i = 0z; i < len(ctx.submods); i += 1) {
			let submodule = if (len(ctx.ident) != 0) {
				const s = unparse::identstr(ctx.ident);
				defer free(s);
				yield strings::concat(s, "::", ctx.submods[i]);
			} else {
				yield strings::dup(ctx.submods[i]);
			};
			defer free(submodule);

			fmt::fprintf(ctx.out, "// - [[")?;
			fmt::fprintf(ctx.out, submodule)?;
			fmt::fprintfln(ctx.out, "]]")?;
		};
	};
};

fn details_hare(ctx: *context, decl: ast::decl) (void | error) = {
	if (len(decl.docs) == 0 && !ctx.show_undocumented) {
		return;
	};

	const iter = strings::tokenize(decl.docs, "\n");
	for (true) {
		match (strings::next_token(&iter)) {
		case void =>
			break;
		case let s: str =>
			if (len(s) != 0) {
				fmt::fprintfln(ctx.out, "//{}", s)?;
			};
		};
	};

	unparse::decl(ctx.out, &unparse::syn_wrap, decl)?;
	fmt::fprintln(ctx.out)?;
	return;
};
