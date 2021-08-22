use fmt;

fn mklabel(ctx: *context, name: str) str = {
	static let buf: [1024]u8 = [0...];
	let serial = ctx.serial;
	ctx.serial += 1;
	return fmt::bsprintf(buf, "@{}.{}", name, serial);
};
