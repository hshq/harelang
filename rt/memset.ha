// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export fn memset(dest: *opaque, val: u8, n: size) void = {
	// implementation adapted from musl libc

	let d = memfunc_ptr { byte = dest: *[*]u8 };

	// fill 4 bytes of head and tail with minimal branching. the head/tail
	// regions may overlap, in which case we return early, and if not
	// then we infer that we can fill twice as much on the next round.
	if (n == 0) return;
	d.byte[0] = val;
	d.byte[n-1] = val;
	if (n <= 2) return;
	d.byte[1] = val;
	d.byte[2] = val;
	d.byte[n-2] = val;
	d.byte[n-3] = val;
	if (n <= 6) return;
	d.byte[3] = val;
	d.byte[n-4] = val;
	// NOTE: we could do more here but the work would be duplicated later
	if (n <= 8) return;

	// advance pointer to align it at a 4-byte boundary,
	// and truncate n to a multiple of 4. the previous code
	// already took care of any head/tail that get cut off
	// by the alignment
	let diff = -d.uptr & 0b11;
	d.uptr = d.uptr + diff;
	n -= diff;
	// convert length in u8 to u32, truncating it in the process
	n >>= 2;

	// 4-byte copy of val
	let val32 = 0x01010101u32 * val;

	// fill 7 u32s (28 bytes) of head and tail, using the same process
	// as before. we don't need to check for n == 0 because we advanced <4
	// bytes out of more than 8, so there's at least one u32 left.
	d.quad[0] = val32;
	d.quad[n-1] = val32;
	if (n <= 2) return;
	d.quad[1] = val32;
	d.quad[2] = val32;
	d.quad[n-2] = val32;
	d.quad[n-3] = val32;
	if (n <= 6) return;
	d.quad[3] = val32;
	d.quad[4] = val32;
	d.quad[5] = val32;
	d.quad[6] = val32;
	d.quad[n-4] = val32;
	d.quad[n-5] = val32;
	d.quad[n-6] = val32;
	d.quad[n-7] = val32;

	// align to a multiple of 8 so we can copy as u64.
	// NOTE: the 24 here skips over most of the head we just filled,
	// while making sure that diff <= 28
	diff = 24 + (d.uptr & 4);
	d.uptr = d.uptr + diff;
	n -= diff >> 2;

	// 28 tail bytes have already been filled, so any remainder
	// when n <= 7 (28 bytes) can be safely ignored
	const val64 = (val32: u64 << 32) | val32;
	for (8 <= n; n -= 8) {
		d.octs[0] = val64;
		d.octs[1] = val64;
		d.octs[2] = val64;
		d.octs[3] = val64;
		d.uptr += 32;
	};
};
