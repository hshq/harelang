// License: MPL-2.0
// (c) 2021 Armin Preiml <apreiml@strohwolke.at>

// An abstract interface for implementing cipher streams
export type stream = struct {
	xor: *fn(s: *stream, dest: []u8, src: []u8) void,
	finish: *fn(s: *stream) void,
};

// Applies xor of the key produced by the stream to src and writes the result
// in dest. 'dest' and 'src' may be the same slice, and both slices must have
// the same length.
export fn stream_xor(s: *stream, dest: []u8, src: []u8) void = {
	assert(len(dest) == len(src), "stream_xor: slices must have the same length");
	s.xor(s, dest, src);
};
