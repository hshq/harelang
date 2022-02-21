// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

export fn memset(dest: *void, val: u8, amt: size) void = {
	let a = dest: *[*]u8;
	for (let i = 0z; i < amt; i += 1) {
		a[i] = val;
	};
};
