use encoding::utf8;

export type end = void;

fn utf8_byte_len_bounded(iter: *iterator, end: size) size = {
	let pos = 0z;
	for (let i = 0z; i < end; i += 1z) {
		let r: rune = match (strings::next(iter)) {
			void => break,
			r: rune => r,
		};

		pos += utf8::runesz(r);
	};
	return pos;
};

fn utf8_byte_len_unbounded(iter: *iterator) size = {
	let pos = 0z;
	for (true) {
		let r: rune = match (strings::next(iter)) {
			void => break,
			r: rune => r,
		};

		pos += utf8::runesz(r);
	};
	return pos;
};

// Returns a substring in the range [start, end - 1]. If the end argument is
// given as [strings::end], the end of the substring is the end of the original
// string. The lifetime of the substring is the same as that of the original
// string.
export fn sub(s: str, start: size, end: (size | end)) str = {
	let iter = iter(s);
	let starti = utf8_byte_len_bounded(&iter, start);
	let endi = match (end) {
		sz: size => starti + utf8_byte_len_bounded(&iter, sz - start),
		end => starti + utf8_byte_len_unbounded(&iter),
	};
	let bytes = to_utf8(s);
	return from_utf8_unsafe(bytes[starti..endi]);
};

@test fn sub() void = {
	assert(sub("a string", 2z, end) == "string");
	assert(sub("a string", 0z, 1z) == "a");
	assert(sub("a string", 0z, 3z) == "a s");
	assert(sub("a string", 2z, 8z) == "string");
};
