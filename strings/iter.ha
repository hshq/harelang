use encoding::utf8;

// An iterator which yields each rune from a string.
//
// [iterator] is very similar to [encoding::utf8::decoder], and in fact is based
// on it. However, an invariant of Hare is that a 'str' type always contains a
// complete, valid UTF-8 string. [iterator] differs from
// [encoding::utf8::decoder] in that it assumes that the string is valid, and
// aborts the program otherwise. This reduces the number of error cases your
// code has to handle when you know you're only dealing with valid strings.
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
