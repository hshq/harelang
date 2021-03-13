// The set of functions used for endian-aware encoding.
export type endian = struct {
	putu32: *fn(buf: []u8, in: u32) void,
	putu64: *fn(buf: []u8, in: u64) void,
};

// Big endian; MSB first.
export const big: endian = endian {
	putu32 = &beputu32,
	putu64 = &beputu64,
};

// Little endian; LSB first.
export const little: endian = endian {
	putu32 = &leputu32,
	putu64 = &leputu64,
};
