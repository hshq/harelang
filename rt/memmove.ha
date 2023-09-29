// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

def SZSZ = size(size);
def MODSZ = size(size) - 1;

export fn memmove(dest: *opaque, src: *const opaque, n: size) void = {
	// implementation adapted from musl libc

	let d = memfunc_ptr { byte = dest: *[*]u8 };
	let s = memfunc_ptr { byte = src: *[*]u8 };

	if (d.uptr == s.uptr) return;
	// equivalent to n <= abs(src - dest)
	if (s.uptr - d.uptr - n <= -2*n) return memcpy(dest, src, n);

	if (d.uptr < s.uptr) {
		// if alignment matches, copy the majority as []size
		if (s.uptr & MODSZ == d.uptr & MODSZ) {
			// use u8 until we reach a word boundary
			for (0 < d.uptr & MODSZ) {
				if (n == 0) return else n -= 1;
				d.byte[0] = s.byte[0];
				d.uptr += 1;
				s.uptr += 1;
			};
			for (SZSZ <= n; n -= SZSZ) {
				d.sz[0] = s.sz[0];
				// TODO: should be +=, blocked on compiler bug
				d.uptr = d.uptr + SZSZ;
				s.uptr = s.uptr + SZSZ;
			};
		};
		for (0 < n; n -= 1) {
			d.byte[0] = s.byte[0];
			d.uptr += 1;
			s.uptr += 1;
		};
	} else {
		d.uptr = d.uptr + n;
		s.uptr = s.uptr + n;
		// if alignment matches, copy the majority as []size
		if (s.uptr & MODSZ == d.uptr & MODSZ) {
			// use u8 until we reach a word boundary
			for (0 < d.uptr & MODSZ) {
				if (n == 0) return else n -= 1;
				d.uptr -= 1;
				s.uptr -= 1;
				d.byte[0] = s.byte[0];
			};
			for (SZSZ <= n; n -= SZSZ) {
				// TODO: should be -=, blocked on compiler bug
				d.uptr = d.uptr - SZSZ;
				s.uptr = s.uptr - SZSZ;
				d.sz[0] = s.sz[0];
			};
		};
		for (0 < n; n -= 1) {
			d.uptr -= 1;
			s.uptr -= 1;
			d.byte[0] = s.byte[0];
		};
	};
};
