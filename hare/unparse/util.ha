// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use io;

fn newline(ctx: *context) (size | io::error) = {
	let n = 0z;
	n += fmt::fprint(ctx.out, "\n")?;
	ctx.linelen = 0;
	for (let i = 0z; i < ctx.indent; i += 1) {
		n += fmt::fprint(ctx.out, "\t")?;
		ctx.linelen += 8;
	};
	return n;
};

fn space(ctx: *context) (size | io::error) = {
	if (ctx.linelen <= ctx.indent * 8) {
		return 0z;
	};
	ctx.linelen += 1;
	return fmt::fprint(ctx.out, " ");
};
