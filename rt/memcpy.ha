// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

def MOD32 = size(u32) - 1;

export fn memcpy(dest: *opaque, src: *const opaque, n: size) void = {
	// implementation adapted from musl libc

	let d = memfunc_ptr { byte = dest: *[*]u8 };
	let s = memfunc_ptr { byte = src: *[*]u8 };

	// copy bytes until src pointer is u32-aligned
	for (s.uptr & MOD32 != 0 && 0 < n; n -= 1) {
		d.byte[0] = s.byte[0];
		d.uptr += 1;
		s.uptr += 1;
	};

	// if dest is u32-aligned with src, copy as batches of u32s
	if (d.uptr & MOD32 == 0) {
		for (16 <= n; n -= 16) {
			d.quad[0] = s.quad[0];
			d.quad[1] = s.quad[1];
			d.quad[2] = s.quad[2];
			d.quad[3] = s.quad[3];
			d.uptr += 16;
			s.uptr += 16;
		};
		if (n & 8 != 0) {
			d.quad[0] = s.quad[0];
			d.quad[1] = s.quad[1];
			d.uptr += 8;
			s.uptr += 8;
		};
		if (n & 4 != 0) {
			d.quad[0] = s.quad[0];
			d.uptr += 4;
			s.uptr += 4;
		};
	} else {
		// TODO: musl uses some byte-order-dependent code here
		// which could be incorporated at some point.
		for (16 <= n; n -= 16) {
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
		};
		if (n & 8 != 0) {
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
		};
		if (n & 4 != 0) {
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
			d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
		};
	};
	if (n & 2 != 0) {
		d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
		d.byte[0] = s.byte[0]; d.uptr += 1; s.uptr += 1;
	};
	if (n & 1 != 0) {
		d.byte[0] = s.byte[0];
	};
};
