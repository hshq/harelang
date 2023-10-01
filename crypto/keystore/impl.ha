// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// TODO: At least use mlock or something
use bytes;
use errors;

export type key = []u8;

// Creates a new secure key. The caller should clear the secret buffer with
// [[bytes::zero]] after initialization.
export fn newkey(buf: []u8, name: str) (key | errors::error) = {
	return alloc(buf...): []u8: key;
};

// Destroys a secure key.
export fn destroy(key: key) void = {
	bytes::zero(key[..]);
	free(key);
};

// Reads secret data from a secure key. When the caller is done using the secret
// buffer, they should use [[bytes::zero]] to securely wipe the buffer memory.
export fn read(key: key, buf: []u8) size = {
	let amt = len(buf);
	if (len(key) < len(buf)) {
		amt = len(key);
	};
	buf[..amt] = key[..amt];
	return amt;
};
