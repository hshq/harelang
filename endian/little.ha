// Writes a u32 into a buffer in big-endian order.
export fn leputu32(buf: []u8, in: u32) void = {
	buf[0] = (in): u8;
	buf[1] = (in >> 8): u8;
	buf[2] = (in >> 16): u8;
	buf[3] = (in >> 24): u8;
};

// Writes a u64 into a buffer in big-endian order.
export fn leputu64(buf: []u8, in: u64) void = {
	buf[0] = (in >> 0): u8;
	buf[1] = (in >> 8): u8;
	buf[2] = (in >> 16): u8;
	buf[3] = (in >> 24): u8;
	buf[4] = (in >> 32): u8;
	buf[5] = (in >> 40): u8;
	buf[6] = (in >> 48): u8;
	buf[7] = (in >> 56): u8;
};

@test fn little() void = {
	let buf: [8]u8 = [0...];
	leputu32(buf, 0x12345678);
	assert(buf[0] == 0x78 && buf[1] == 0x56
		&& buf[2] == 0x34 && buf[3] == 0x12);
	leputu64(buf, 0x1234567887654321);
	assert(buf[0] == 0x21 && buf[1] == 0x43
		&& buf[2] == 0x65 && buf[3] == 0x87
		&& buf[4] == 0x78 && buf[5] == 0x56
		&& buf[6] == 0x34 && buf[7] == 0x12);
};
