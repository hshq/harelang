// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use rt;
use types;

// Appends an item, or multiple items, to a slice, reallocating if necessary.
export fn appendto(sl: *[]void, itemsz: size, items: const *void...) void = {
	const repr = sl: *types::slice;
	insertinto(sl, itemsz, repr.length, items...);
};

@test fn appendto() void = {
	let input: []int = [];
	let num = 1337;
	appendto(&input: *[]void, size(int), &num, &num);
	assert(len(input) == 2 && input[0] == 1337 && input[1] == 1337);
	num = 7331;
	appendto(&input: *[]void, size(int), &num);
	assert(len(input) == 3 && input[0] == 1337 && input[1] == 1337
		&& input[2] == 7331);
	free(input);
};

// Appends an item, or multiple items, to a slice. Aborts if the slice's
// capacity isn't large enough to fit the items.
export fn static_appendto(
	sl: *[]void,
	itemsz: size,
	items: const *void...
) void = {
	const repr = sl: *types::slice;
	static_insertinto(sl, itemsz, repr.length, items...);
};

// Inserts an item, or multiple items, to a slice, in O(n) time, reallocating if
// necessary.
export fn insertinto(
	sl: *[]void,
	itemsz: size,
	idx: size,
	items: const *void...
) void = {
	if (len(items) == 0) {
		return;
	};
	let sl = sl: *types::slice;
	sl.length += len(items);
	rt::ensure(sl, itemsz);
	let data = sl.data: *[*]u8;
	rt::memmove(&data[(idx + len(items)) * itemsz], &data[idx * itemsz],
		(sl.length - len(items) - idx) * itemsz);
	for (let i = 0z; i < len(items); i += 1) {
		rt::memcpy(&data[(idx + i) * itemsz], items[i], itemsz);
	};
};

@test fn insertinto() void = {
	let input: []int = alloc([1, 3], 2);
	let num = 2;
	insertinto(&input: *[]void, size(int), 1, &num, &num);
	assert(len(input) == 4 && input[0] == 1 && input[1] == 2
		&& input[2] == 2 && input[3] == 3);
	free(input);
};

// Inserts an item, or multiple items, into a slice, in O(n) time. Aborts if the
// slice's capacity isn't large enough to fit the items.
export fn static_insertinto(
	sl: *[]void,
	itemsz: size,
	idx: size,
	items: const *void...
) void = {
	if (len(items) == 0) {
		return;
	};
	let sl = sl: *types::slice;
	sl.length += len(items);
	assert(sl.length <= sl.capacity,
		"static insert/append exceeds slice capacity");
	let data = sl.data: *[*]u8;
	rt::memmove(&data[(idx + len(items)) * itemsz], &data[idx * itemsz],
		(sl.length - len(items) - idx) * itemsz);
	for (let i = 0z; i < len(items); i += 1) {
		rt::memcpy(&data[(idx + i) * itemsz], items[i], itemsz);
	};
};

// Deletes a range of items from a slice, in O(n) time. The slice may be
// reallocated. Reallocation will never fail.
export fn deletefrom(sl: *[]void, itemsz: size, start: size, end: size) void = {
	static_deletefrom(sl, itemsz, start, end);
	let sl = sl: *types::slice;
	if (sl.length <= sl.capacity / 2) {
		// TODO: switch to using alloc() once it's possible to handle
		// copy allocation errors
		match (rt::realloc(sl.data, sl.length * itemsz)) {
		case null => void;
		case let p: *void =>
			sl.data = p;
			sl.capacity = sl.length;
		};
	};
};

@test fn deletefrom() void = {
	let input: []int = alloc([1, 2, 3, 4, 5], 5);
	deletefrom(&input: *[]void, size(int), 1, 1);
	assert(len(input) == 5);
	deletefrom(&input: *[]void, size(int), 1, 3);
	assert(len(input) == 3 && input[0] == 1 && input[1] == 4
		&& input[2] == 5);
	free(input);
};

// Deletes a range of items from a slice, in O(n) time, without freeing memory.
export fn static_deletefrom(
	sl: *[]void,
	itemsz: size,
	start: size,
	end: size,
) void = {
	assert(start <= end);
	assert(itemsz != 0);
	if (start == end) {
		return;
	};
	let sl = sl: *types::slice;
	let data = sl.data: *[*]u8;
	rt::memmove(&data[start * itemsz], &data[end * itemsz],
		(sl.length - end) * itemsz);
	sl.length -= end - start;
};

// Swaps two elements of a slice.
export fn swap(sl: []void, itemsz: size, a: size, b: size) void = {
	assert(a < len(sl) && b < len(sl));
	let sl = sl: *[*]u8;
	let a = &sl[a * itemsz]: *[*]u8, b = &sl[b * itemsz]: *[*]u8;
	for (let i = 0z; i < itemsz; i += 1) {
		let c = a[i];
		a[i] = b[i];
		b[i] = c;
	};
};

@test fn swap() void = {
	let x: []int = [1, 2, 3];
	swap(x: []void, size(int), 0, 2);
	assert(x[0] == 3 && x[2] == 1);
};

// Returns a pointer to the nth item of a slice.
export fn index(sl: []void, itemsz: size, n: size) *void = {
	assert(n < len(sl));
	let ba = sl: *[*]u8;
	return &ba[n * itemsz];
};

@test fn index() void = {
	let x: []int = [1, 2, 3];
	let ptr = index(x, size(int), 1): *int;
	assert(*ptr == 2);
};
