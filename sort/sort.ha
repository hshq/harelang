// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Steven Guikal <void@fluix.one>

// Sorts a slice of items in place.
//
// Note that this function may (temporarily) allocate, and will abort on
// allocation failure.
export fn sort(items: []void, itemsz: size, cmp: *cmpfunc) void = {
	if (len(items) < 256) {
		insort(items, itemsz, cmp);
		return;
	};

	// TODO: Timsort
	insort(items, itemsz, cmp);
};

// Sorts a slice of strings in place. Sorting is done with respect to Unicode
// codepoints; see [[strings::strcmp]].
export fn strings(items: []str) void = sort(items, size(str), &scmp);

// Checks if all of the items in a slice are sorted.
export fn sorted(items: []void, itemsz: size, cmp: *cmpfunc) bool = {
	for (let i = 0z; i < len(items) - 1; i += 1) {
		if (cmp(&items[i], &items[i + 1]) > 0) {
			return false;
		};
	};
	return true;
};

// Checks if all of the strings in a slice are sorted. Order is checked with
// respect to Unicode codepoints; see [[strings::strcmp]].
export fn strings_sorted(items: []str) bool = sorted(items, size(str), &scmp);

fn swap(a: *void, b: *void, sz: size) void = {
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
	in: []void,
	sz: size,
	key: const *void,
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

fn insort(items: []void, itemsz: size, cmp: *cmpfunc) void = {
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
