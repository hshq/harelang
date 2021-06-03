// Sorts a slice of items in place. Provide a slice of 'items', the size of each
// member, and a function to compare one member to another. The 'cmp' function
// will be called with two pointers to values within the items slice, and shall
// return an integer less than, equal to, or greater than zero if the first
// argument is, respectively, less than, equal to, or greater than the second
// argument.
//
// This implementation provides a stable sort.
export fn sort(
	items: []void,
	itemsz: size,
	cmp: *fn(a: const *void, b: const *void) int,
) void = {
	if (len(items) < 256) {
		insort(items, itemsz, cmp);
		return;
	};

	// TODO: Timsort
	insort(items, itemsz, cmp);
};

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
	cmp: *fn(a: const *void, b: const *void) int,
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

fn insort(
	items: []void,
	itemsz: size,
	cmp: *fn(a: const *void, b: const *void) int,
) void = {
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
