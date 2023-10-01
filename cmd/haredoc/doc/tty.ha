// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use ascii;
use bufio;
use fmt;
use hare::ast;
use hare::unparse;
use io;
use memio;
use os;
use strings;
use types;

let firstline: bool = true;
let no_color: bool = false;

// Formats output as Hare source code (prototypes) with syntax highlighting
export fn emit_tty(ctx: *context) (void | error) = {
	if (os::tryenv("NO_COLOR", "") == "") {
		init_colors()?;
	} else {
		no_color = true;
	};
	const summary = ctx.summary;

	match (ctx.readme) {
	case let readme: io::file =>
		let rbuf: [os::BUFSZ]u8 = [0...];
		let readme = bufio::init(readme, rbuf, []);
		let sc = bufio::newscanner(&readme, types::SIZE_MAX);
		defer bufio::finish(&sc);
		for (true) match (bufio::scan_line(&sc)?) {
		case io::EOF => break;
		case let s: const str =>
			firstline = false;
			if (!no_color) fmt::fprintf(ctx.out, "\x1b[{}m",
				color(unparse::synkind::COMMENT))?;
			fmt::fprint(ctx.out, "//", s)?;
			if (!no_color) fmt::fprint(ctx.out, "\x1b[m")?;
			fmt::fprintln(ctx.out)?;
		};
	case void => void;
	};

	emit_submodules_tty(ctx)?;

	// XXX: Should we emit the dependencies, too?
	for (let i = 0z; i < len(summary.types); i += 1) {
		details_tty(ctx, summary.types[i])?;
	};
	for (let i = 0z; i < len(summary.constants); i += 1) {
		details_tty(ctx, summary.constants[i])?;
	};
	for (let i = 0z; i < len(summary.errors); i += 1) {
		details_tty(ctx, summary.errors[i])?;
	};
	for (let i = 0z; i < len(summary.globals); i += 1) {
		details_tty(ctx, summary.globals[i])?;
	};
	for (let i = 0z; i < len(summary.funcs); i += 1) {
		details_tty(ctx, summary.funcs[i])?;
	};
};

fn emit_submodules_tty(ctx: *context) (void | error) = {
	if (len(ctx.submods) != 0) {
		fmt::fprintln(ctx.out)?;
		if (!no_color) fmt::fprintf(ctx.out, "\x1b[{}m",
			color(unparse::synkind::COMMENT))?;
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

			fmt::fprintfln(ctx.out, "// - [[{}]]", submodule)?;
		};
	};
};

fn details_tty(ctx: *context, decl: ast::decl) (void | error) = {
	if (len(decl.docs) == 0 && !ctx.show_undocumented) {
		return;
	};

	if (!no_color) fmt::fprint(ctx.out, "\x1b[m")?; // reset styling
	if (!firstline) {
		fmt::fprintln(ctx.out)?;
	};
	firstline = false;

	unparse::decl(ctx.out, &syn_tty, decl)?;
	fmt::fprintln(ctx.out)?;
};

fn syn_tty(
	ctx: *unparse::context,
	s: str,
	kind: unparse::synkind,
) (size | io::error) = {
	let z = 0z;
	if (!no_color) z += fmt::fprintf(ctx.out, "\x1b[{}m", color(kind))?;
	z += unparse::syn_wrap(ctx, s, kind)?;
	if (!no_color) z += fmt::fprint(ctx.out, "\x1b[m")?;
	return z;
};
