// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
// TODO: Use a vtable-based approach for this like io::stream

// The general purpose interface for a hashing function.
export type hash = struct {
	// A stream which only supports writes and never returns errors.
	stream: io::stream,

	// Returns the current hash.
	sum: *fn(hash: *hash, buf: []u8) void,

	// Resets the hash function to its initial state.
	reset: nullable *fn(hash: *hash) void,

	// Size of the hash in bytes.
	sz: size,

	// Internal block size of the hash. Writing data to the hash
	// function in chunks of this size will not require padding to
	// obtain the final hash.
	bsz: size,
};

// Writes an input to the hash function.
export fn write(h: *hash, buf: const []u8) size =
	io::write(h, buf) as size;

// Closes a hash, freeing its resources and discarding the checksum.
export fn close(h: *hash) void = io::close(h)!;

// Populates the user-provided buffer with the current sum.
export fn sum(h: *hash, buf: []u8) void = {
	assert(len(buf) >= h.sz, "hash::sum buffer does not meet minimum required size for this hash function");
	h.sum(h, buf);
};

// Resets the hash function to its initial state.
export fn reset(h: *hash) void = match (h.reset) {
case let f: *fn(hash: *hash) void =>
	f(h);
case null =>
	abort("this hash cannot be reset");
};

// Returns the size of the hash in bytes. This is consistent regardless
// of the hash state.
export fn sz(h: *hash) size = h.sz;

// Returns the block size of the hash.
export fn bsz(h: *hash) size = h.bsz;
