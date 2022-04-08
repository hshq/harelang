// License: MPL-2.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use types;

// Returns the capacity of a string.
export fn cap(s: str) size = {
	const s = &s: *types::string;
	return s.capacity;
};
