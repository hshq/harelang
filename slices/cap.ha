// License: MPL-2.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use types;

// Returns the capacity of a slice.
export fn cap(slice: []const void) size = {
	const slice = &slice: *types::slice;
	return slice.capacity;
};
