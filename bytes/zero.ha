// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// Sets all bytes in a slice to zero. This is suitable for erasing private data
// from a slice.
export fn zero(buf: []u8) void = {
	for (let i = 0z; i < len(buf); i += 1) {
		buf[i] = 0;
	};
};
