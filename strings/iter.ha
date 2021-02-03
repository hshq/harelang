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
export fn iterstr(iter: *iterator) str = {
	return from_utf8(iter.src[iter.offs..]);
};
