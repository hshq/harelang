use bytes;
use io;
use strconv;
use strings;
use strio;

// Error returned when attempting to decode an invalid hex string.
export type invalid = void!;

// Encodes a byte slice to hex and writes it to a string. The caller must free
// this string.
export fn encode(b: []u8) str = {
	let buf = strio::dynamic();
	for (let i = 0z; i < len(b); i += 1) {
		let s = strconv::u8tosb(b[i], strconv::base::HEX_LOWER);
		if (len(s) == 1) {
			io::write(buf, ['0': u32: u8]);
		};
		io::write(buf, strings::toutf8(s)) as size;
	};
	return strio::finish(buf);
};

@test fn encode() void = {
	let in: [_]u8 = [0xCA, 0xFE, 0xBA, 0xBE, 0xDE, 0xAD, 0xF0, 0x0D];
	let s = encode(in);
	defer free(s);
	assert(s == "cafebabedeadf00d");
};

// Decodes a string of hexadecimal bytes into a byte slice. The caller must free
// the return value.
export fn decode(s: str) ([]u8 | invalid) = {
	if (len(s) % 2 != 0) {
		return invalid;
	};
	let buf: []u8 = alloc([], len(s) / 2);
	let s = strings::toutf8(s);
	for (let i = 0z; i < len(s) / 2; i += 1) {
		let oct = strings::fromutf8_unsafe(s[i * 2..i * 2 + 2]);
		let u = match (strconv::stou8b(oct, 16)) {
			(strconv::invalid | strconv::overflow) => return invalid,
			u: u8 => u,
		};
		append(buf, u);
	};
	return buf;
};

@test fn decode() void = {
	let s = decode("cafebabedeadf00d") as []u8;
	defer free(s);
	assert(bytes::equal(s, [0xCA, 0xFE, 0xBA, 0xBE, 0xDE, 0xAD, 0xF0, 0x0D]));

	decode("this is not hex") as invalid;
};
