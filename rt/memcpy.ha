// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

export fn memcpy(dest: *opaque, src: *const opaque, amt: size) void = {
	let a = dest: *[*]u8, b = src: *const [*]u8;
	for (let i = 0z; i < amt; i += 1) {
		a[i] = b[i];
	};
};
