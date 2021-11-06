use types;

// Truncates a slice, setting its length to zero without freeing the underlying
// storage or altering its capacity.
export fn trunc(sl: *[]void) void = {
	let sl = sl: *types::slice_repr;
	sl.length = 0;
};
