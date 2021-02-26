use io;
use strconv;
use strings;
use strio;

// Encodes a byte slice to hex and writes it to a string. The caller must free
// this string.
export fn encode(b: []u8) str = {
	let buf = strio::dynamic();
	for (let i = 0z; i < len(b); i += 1) {
		let s = strconv::u8tosb(b[i], strconv::base::HEX_LOWER);
		if (len(s) == 1) {
			io::write(buf, ['0': u32: u8]);
		};
		io::write(buf, strings::to_utf8(s)) as size;
	};
	return strio::finish(buf);
};

@test fn encode() void = {
	let in: [_]u8 = [0xCA, 0xFE, 0xBA, 0xBE, 0xDE, 0xAD, 0xF0, 0x0D];
	let s = encode(in);
	defer free(s);
	assert(s == "cafebabedeadf00d");
};
