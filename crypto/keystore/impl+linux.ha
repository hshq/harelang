// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use linux::keyctl;

export type key = keyctl::serial;

// Creates a new secure key. The caller should clear the secret buffer with
// [[bytes::zero]] after initialization.
export fn newkey(buf: []u8, name: str) (key | errors::error) = {
	match (keyctl::add_key("user", name, buf, keyctl::PROCESS_KEYRING)) {
	case keyctl::nokey => abort();
	case let err: errors::error =>
		return err;
	case let key: keyctl::serial =>
		return key;
	};
};

// Destroys a secure key.
export fn destroy(key: key) void = {
	keyctl::revoke(key)!;
};

// Reads secret data from a secure key. When the caller is done using the secret
// buffer, they should use [[bytes::zero]] to securely wipe the buffer memory.
export fn read(key: key, buf: []u8) size = {
	return keyctl::read(key, buf)!;
};
