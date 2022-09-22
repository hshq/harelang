use encoding::hex;

// The caller must free the result.
export fn fromhex(h: str) []word = {
	let n: []u8 = hex::decodestr(h)!;
	defer free(n);

	let i: []word = alloc([0...], encodelen(n));
	encode(i, n);
	return i;
};

// 'h' must be lower than 'm'
export fn fromhexmod(h: str, m: []word) []word = {
	let r = fromhex(h);
	r[0] = m[0];
	return r;
};

// The caller must free the result.
export fn tohex(x: []word) str = {
	let buf: []u8 = alloc([0...], (len(x) - 1) * size(word));
	defer free(buf);

	decode(buf, x);

	let i = 0z;
	for (i < len(buf); i += 1) {
		if (buf[i] != 0) {
			break;
		};
	};

	return hex::encodestr(buf[i..]);
};

export fn equalshex(x: []word, h: str) bool = {
	let result = tohex(x);
	defer free(result);
	return result == h;
};
