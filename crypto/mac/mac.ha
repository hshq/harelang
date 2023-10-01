// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
// TODO: Use a vtable-based approach like io::stream

// The general purpose interface for a MAC function.
export type mac = struct {
	// A stream which only supports writes and never returns errors.
	stream: io::stream,

	// Writes the resulting MAC to 'buf'. Must only be called once, and must
	// be followed by calling [[finish]].
	sum: nullable *fn(mac: *mac, buf: []u8) void,

	// Finalizes the MAC function, securely discards all state and frees
	// all resources used by the MAC.
	finish: *fn(mac: *mac) void,

	// Size of the MAC in bytes.
	sz: size,

	// Internal block size of the MAC in bytes.
	bsz: size,
};

// Writes an input to the MAC function.
export fn write(m: *mac, buf: const []u8) size = io::write(m, buf) as size;

// Computes the final MAC and writes it to 'buf', which must be at least [[sz]]
// bytes. Generally, each MAC implementation provides a constant which is equal
// to the length, so you may not have to dynamically allocate this buffer.
//
// This function may only be called once for any given [[mac]] object; calling
// it more than once will cause a runtime assertion to fail.
//
// After calling [[sum]], you must call [[finish]] to securely erase sensitive
// information stored in the MAC function state.
export fn sum(m: *mac, buf: []u8) void = {
	assert(len(buf) >= m.sz,
		"mac::finish buffer does not meet minimum required size");

	match(m.sum) {
	case let f: *fn(mac: *mac, buf: []u8) void =>
		f(m, buf);
		m.sum = null;
	case null =>
		abort("MAC is already finished or sum has already been called");
	};
};

// Finalizes the MAC function, securely discarding any sensitive state, and
// freeing any associated resources.
export fn finish(m: *mac) void = {
	m.finish(m);
	m.sum = null;
};

// Returns the size of the MAC in bytes. This is consistent regardless
// of the MAC state.
export fn sz(m: *mac) size = m.sz;

// Returns the block size of the MAC in bytes.
export fn bsz(m: *mac) size = m.bsz;
