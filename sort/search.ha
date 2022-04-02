// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// Performs a binary search over a sorted slice. If the key is found, a pointer
// to the matching item in the slice is returned. Otherwise, null is returned.
export fn search(
	in: []const void,
	sz: size,
	key: const *void,
	cmp: *cmpfunc,
) nullable *const void = {
	let ba = in: *[*]u8;
	for (let nmemb = len(in); nmemb > 0) {
		let v = &ba[nmemb / 2 * sz];
		let r = cmp(key, v);
		if (r < 0) {
			nmemb /= 2;
		} else if (r > 0) {
			ba = (v: uintptr + sz: uintptr): *[*]u8;
			nmemb -= nmemb / 2 + 1;
		} else {
			return v;
		};
	};
	return null;
};

// Performs a binary search over a sorted slice of strings. Sorting is done with
// respect to Unicode codepoints; see [[strings::strcmp]]. The index of the
// matching item in the slice is returned if found, otherwise void is returned.
export fn searchstrings(in: []const str, key: str) (size | void) = {
	match (search(in, size(str), &key, &scmp)) {
	case null =>
		return void;
	case let v: *const void =>
		const offs = (v: uintptr - in: *[*]const str: uintptr);
		return (offs / size(str): uintptr): size;
	};
};
