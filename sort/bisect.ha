// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Determines the index that 'elem' should be inserted into sorted slice 'in'.
// If 'elem' already appears in the slice, inserting to the returned index will
// insert immediately before the first occurance.
export fn lbisect(
	in: []const opaque,
	sz: size,
	elem: const *opaque,
	cmp: *cmpfunc,
) size = {
	let min = 0z, max = len(in);
	const in = in: *[*]u8;
	for (min < max) {
		let i = (max - min) / 2 + min;
		const r = cmp(elem, &in[i * sz]);
		if (r < 0) {
			max = i;
		} else if (r > 0) {
			min = i + 1;
		} else {
			if (i == 0) return 0;
			for (i > 0; i -= 1) {
				if (cmp(elem, &in[(i - 1) * sz]) != 0) {
					break;
				};
			};
			return i;
		};
	};
	return max;
};

// Determines the index that 'elem' should be inserted into sorted slice 'in'.
// If 'elem' already appears in the slice, inserting to the returned index will
// insert immediately after the last occurance.
export fn rbisect(
	in: []const opaque,
	sz: size,
	elem: const *opaque,
	cmp: *cmpfunc,
) size = {
	const nmemb = len(in);
	let min = 0z, max = nmemb;
	const in = in: *[*]u8;
	for (min < max) {
		let i = (max - min) / 2 + min;
		const r = cmp(elem, &in[i * sz]);
		if (r < 0) {
			max = i;
		} else if (r > 0) {
			min = i + 1;
		} else {
			i += 1;
			for (i < nmemb; i += 1) {
				if (cmp(elem, &in[i * sz]) != 0) {
					break;
				};
			};
			return i;
		};
	};
	return max;
};
