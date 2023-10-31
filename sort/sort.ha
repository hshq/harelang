// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use math;
use types;

// Sorts a slice of items in place. This function provides a stable sort -
// relative order of equal elements is preserved.
//
// Note that this function may (temporarily) allocate, and will abort on
// allocation failure.
export fn sort(items: []opaque, itemsz: size, cmp: *cmpfunc) void = {
	if (len(items) < 256) {
		insort(items, itemsz, cmp);
		return;
	};
	powersort(items, itemsz, cmp);
};

// Checks if all of the items in a slice are sorted.
export fn sorted(items: []opaque, itemsz: size, cmp: *cmpfunc) bool = {
	let ba = items: *[*]u8;
	for (let i = 1z; i < len(items); i += 1) {
		if (cmp(&ba[(i - 1) * itemsz], &ba[i * itemsz]) > 0) {
			return false;
		};
	};
	return true;
};

fn swap(a: *opaque, b: *opaque, sz: size) void = {
	let a = a: *[*]u8, b = b: *[*]u8;
	for (let i = 0z; i < sz; i += 1) {
		let c = a[i];
		a[i] = b[i];
		b[i] = c;
	};
};

// Finds the index of the rightmost value that is equal to key or, if such value
// does not exist, less than key.
fn search_rightmost(
	in: []opaque,
	sz: size,
	key: const *opaque,
	cmp: *cmpfunc,
) size = {
	let l = 0z;
	let r = len(in);
	let ba = in: *[*]u8;
	for (l < r) {
		let m = l + (r - l) / 2;
		if (cmp(key, &ba[m * sz]) < 0) {
			r = m;
		} else {
			l = m + 1;
		};
	};
	return r - 1;
};

fn insort(items: []opaque, itemsz: size, cmp: *cmpfunc) void = {
	let ba = items: *[*]u8;
	for (let i = 0z; i < len(items); i += 1) {
		let bound = search_rightmost(items[0..i], itemsz,
			&ba[i * itemsz], cmp);
		for (let j = i; j > bound + 1; j -= 1) {
			let a = &ba[(j - 1) * itemsz];
			let b = &ba[j * itemsz];
			swap(a, b, itemsz);
		};
	};
};

// Based on paper "Nearly-Optimal Mergesorts: Fast, Practical Sorting Methods
// That Optimally Adapt to Existing Runs"; J. Ian Munro, Sebastian Wild
//
// https://arxiv.org/pdf/1805.04154.pdf

def MINRUN: size = 24; // FIXME: needs tuning
def EMPTY: size = -1z;

// A run of non-decreasing elements on the interval [start; end).
type run = struct {
	start: size, // Set to EMPTY when a run is merged
	end: size,
};

fn powersort(items: []opaque, itemsz: size, cmp: *cmpfunc) void = {
	// npowers = floor(log2(n)) + 1
	const npowers = math::bit_size_u64(len(items)) + 1;
	const runs: []run = alloc([run { start = EMPTY, ... }...], npowers + 1);
	defer free(runs);
	let top = 0u8;

	const aux: []u8 = alloc([0...], len(items) * itemsz);
	defer free(aux);

	let a = run {
		start = 0z,
		end = extend(items, itemsz, cmp, 0),
	};
	const length = a.end - a.start;
	if (length < MINRUN) {
		a.end = if (a.start + MINRUN < len(items))
			a.start + MINRUN else len(items);
		insort(cut(items, itemsz, a.start, a.end), itemsz, cmp);
	};
	for (a.end < len(items)) {
		let b = run {
			start = a.end,
			end = extend(items, itemsz, cmp, a.end),
		};
		const length = b.end - b.start;
		if (length < MINRUN) {
			b.end = if (b.start + MINRUN < len(items))
				b.start + MINRUN else len(items);
			insort(cut(items, itemsz, b.start, b.end), itemsz, cmp);
		};
		const k = node_power(0, len(items), a.start, b.start, b.end);
		assert(k != top);
		for (let i = top; i > k; i -= 1) {
			if (runs[i].start == EMPTY) continue;
			merge(items, itemsz, cmp, aux,
				runs[i].start, runs[i].end, a.end);

			a.start = runs[i].start;
			runs[i].start = EMPTY;
		};
		runs[k] = a;
		top = k;

		a = b;
	};
	assert(a.end == len(items));
	for (let i = top; i > 0; i -= 1) {
		if (runs[i].start == EMPTY) continue;
		merge(items, itemsz, cmp, aux,
			runs[i].start, runs[i].end, len(items));
	};
};

// Returns 'end' such that [start; end) in 'items' is non-decreasing
//
//     a[0] ≤ a[1] ≤ ... ≤ a[n - 1] - kept as-is
//     a[1] > a[1] > ... > a[n - 1] - reversed
//
// Note: reversing a sequence with equal elements will move their relative
// locations, which is undesirable for a stable sort.
fn extend(items: []opaque, itemsz: size, cmp: *cmpfunc, start: size) size = {
	const n = len(items);
	const items = (items: *[*]u8)[..len(items) * itemsz];

	assert(n - start > 0, "Empty extension");
	if (start + 1 == n) {
		return n;
	};

	if (cmp(&items[start * itemsz], &items[(start + 1) * itemsz]) <= 0) {
		let end = start + 2;
		for (end < n && cmp(&items[(end - 1) * itemsz], &items[end * itemsz]) <= 0) {
			end += 1;
		};
		return end;
	} else {
		let end = start + 2;
		for (end < n && cmp(&items[(end - 1) * itemsz], &items[end * itemsz]) > 0) {
			end += 1;
		};
		reverse(cut(items, itemsz, start, end), itemsz);
		return end;
	};
};

fn reverse(items: []opaque, itemsz: size) void = {
	const n = len(items);
	const items = (items: *[*]u8)[..n * itemsz];
	for (let i = 0z; i < n / 2; i += 1) {
		swap(&items[i * itemsz], &items[(n - i - 1) * itemsz], itemsz);
	};
};

fn merge(
	items: []opaque,
	itemsz: size,
	cmp: *cmpfunc,
	aux: []u8,
	l: size,
	m: size,
	r: size,
) void = {
	l *= itemsz;
	m *= itemsz;
	r *= itemsz;

	const items = items: *[*]u8;
	// Placing items at the beginning results in better cache performance
	// (probably)
	aux[..m - l] = items[l..m];

	let i = 0z, j = m, out = l;
	for (i < m - l && j < r; out += itemsz) {
		if (cmp(&aux[i], &items[j]) < 0) {
			items[out..out + itemsz] = aux[i..i + itemsz];
			i += itemsz;
		} else {
			items[out..out + itemsz] = items[j..j + itemsz];
			j += itemsz;
		};
	};
	if (i < m - l) {
		const sz = (m - l) - i;
		items[out..out + sz] = aux[i..i + sz];
		out += sz;
	};
	if (j < r) {
		const sz = r - j;
		items[out..out + sz] = items[j..j + sz];
		out += sz;
	};
};

fn cut(items: []opaque, itemsz: size, l: size, r: size) []opaque = {
	return *(&types::slice {
		data = &(items: *[*]u8)[l * itemsz],
		length = r - l,
		capacity = 0,
	}: *[]opaque);
};

fn node_power(left: size, right: size, start_a: size, start_b: size, end_b: size) u8 = {
	const n: u64 = right - left;
	const l: u64 = start_a + start_b - 2 * left;
	const r: u64 = start_b + end_b - 2 * left;
	const a = ((l << 30) / n): u32;
	const b = ((r << 30) / n): u32;
	return math::leading_zeros_u32(a ^ b);
};
