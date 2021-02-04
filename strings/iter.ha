use encoding::utf8;

// An iterator which yields each rune from a string.
export type iterator = utf8::decoder;

// Initializes a string iterator.
export fn iter(src: str) iterator = utf8::decode(src);

// Get the next rune from an iterator, or void if there are none left.
export fn next(iter: *iterator) (rune | void) = {
	return match (utf8::next(iter)) {
		r: rune       => r,
		void          => void,
		utf8::more    => abort("Invalid UTF-8 string (this should not happen)"),
		utf8::invalid => abort("Invalid UTF-8 string (this should not happen)"),
	};
};

// Return a substring from the next rune to the end of the string.
export fn iter_str(iter: *iterator) str = {
	return from_utf8(iter.src[iter.offs..]);
};

@test fn iter_test() void = {
	let s = iter("こんにちは");
	const expected1 = ['こ', 'ん'];
	for (let i = 0z; i < len(expected1); i += 1z) {
		match (next(&s)) {
		r: rune => assert(r == expected1[i]),
		void    => abort(),
		};
	};
	assert(iter_str(&s) == "にちは");
	const expected2 = ['に', 'ち', 'は'];
	for (let i = 0z; i < len(expected2); i += 1z) {
		match (next(&s)) {
		r: rune => assert(r == expected2[i]),
		void    => abort(),
		};
	};
	assert(next(&s) is void);
	assert(next(&s) is void);
};
