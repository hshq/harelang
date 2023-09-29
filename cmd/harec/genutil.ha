// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fmt;

fn mklabel(ctx: *context, name: str) str = {
	static let buf: [1024]u8 = [0...];
	let serial = ctx.serial;
	ctx.serial += 1;
	return fmt::bsprintf(buf, "@{}.{}", name, serial);
};

fn mktemp(ctx: *context) temporary = {
	let serial = ctx.serial;
	ctx.serial += 1;
	return fmt::asprintf(".{}", serial);
};

fn mklval(ctx: *context, val: value) qtypeval = (ctx.arch.ptr, val.value);
