use io;
use fmt;

// The general purpose interface for a hashing function.
export type hash = struct {
	// A stream which only supports writes and never returns errors.
	stream: io::stream,

	// Returns the current hash.
	sum: *fn(hash: *hash, buf: []u8) void,

	// Resets the hash function to its initial state.
	reset: *fn(hash: *hash) void,

	// Size of the hash in bytes.
	sz: size,
};

// Returns a writable [[io::stream]] for a given hash.
export fn writer(h: *hash) *io::stream = &h.stream;

// Writes an input to the hash function.
export fn write(h: *hash, buf: const []u8) size =
	io::write(&h.stream, buf) as size;

// Finalizes the hash, frees resources associated with the hash, and populate
// buf with the sum.
export fn finish(h: *hash, buf: []u8) void = {
	sum(h, buf);
	io::close(&h.stream);
	return buf;
};

// Closes a hash, freeing its resources and discarding the checksum.
export fn close(h: *hash) void = io::close(&h.stream);

// Populates the user-provided buffer with the current sum.
export fn sum(h: *hash, buf: []u8) void = {
	assert(len(buf) >= h.sz, "hash::sum buffer does not meet minimum required size for this hash function");
	h.sum(h, buf);
};

// Resets the hash function to its initial state.
export fn reset(h: *hash) void = h.reset(h);

// Returns the size of the hash in bytes. This is consistent regardless
// of the hash state.
export fn sz(h: *hash) size = h.sz;
