// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

// Implements the so called Two-way string matching algorithm by Crochemore and
// Perrin. It pre-processes the needle in O(len(needle)) steps and performs the
// matching in O(len(haystack)) steps. It does so without any space overhead.
fn index_tw(haystack: []u8, needle: []u8) (size | void) = {
	const n = len(haystack);
	const m = len(needle);
	if (n < m) {
		return void;
	};
	if (n == m) {
		return if (equal(haystack, needle)) 0 else void;
	};

	// pre-processing
	let tup1 = max_suf(needle, false);
	let i = tup1.0, p = tup1.1;
	let tup2 = max_suf(needle, true);
	let j = tup2.0, q = tup2.1;
	let ms = i;
	let per = p;
	if (i + 1 < j + 1) {
		ms = j;
		per = q;
	};

	let mem0 = 0z, mem = 0z;
	if (equal(haystack[..ms + 1], haystack[per..per + ms + 1])) {
		if (ms + 1 > m - ms - 1) {
			per = ms + 2;
		} else {
			per = m - ms;
		};
		mem0 = m - per;
	};


	j = 0;
	for (j <= n - m) {
		// right half
		i = if (ms + 1 > mem) ms + 1 else mem;
		for (i < m && needle[i] == haystack[j + i]) {
			i += 1;
		};
		if (i < m) {
			j += i - ms;
			mem = 0;
			continue;
		};

		// left half
		i = ms + 1;
		for (i > mem && needle[i - 1] == haystack[j + i - 1]) {
			i -= 1;
		};
		if (i <= mem) {
			return j;
		};
		j += per;
		mem = mem0;
	};
};

fn max_suf(x: []u8, inv: bool) (size, size) = {
	let i = types::SIZE_MAX;
	let j = 0z;
	let k = 1z, p = 1z;
	let m = len(x);
	for (j + k < m) {
		let a = x[j + k];
		let b = x[i + k];
		if (a == b) {
			if (k == p) {
				j += p;
				k = 1;
			} else {
				k += 1;
			};
		} else if (a < b ^^ inv) {
			j += k;
			k = 1;
			p = j - i;
		} else {
			i = j;
			j += 1;
			k = 1;
			p = 1;
		};
	};
	return (i, p);
};
