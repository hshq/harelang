// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use types;

// Truncates a slice, setting its length to zero without freeing the underlying
// storage or altering its capacity.
export fn trunc(sl: *[]void) void = {
	let sl = sl: *types::slice;
	sl.length = 0;
};
