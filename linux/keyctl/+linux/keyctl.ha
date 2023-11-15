// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use errors;
use rt;
use types::c;

fn errno(errno: rt::errno) error = {
	switch (errno) {
	case rt::ENOKEY =>
		return nokey;
	case =>
		return errors::errno(errno);
	};
};

// Adds a key to the kernel's key management facility.
export fn add_key(
	keytype: str,
	name: str,
	payload: []u8,
	keyring: serial,
) (serial | error) = {
	const keytype = c::fromstr(keytype);
	defer free(keytype);
	const name = c::fromstr(name);
	defer free(name);
	match (rt::add_key(keytype: *const u8, name: *const u8,
			payload: *[*]u8: *opaque, len(payload), keyring)) {
	case let err: rt::errno =>
		return errno(err);
	case let n: int =>
		return n: serial;
	};
};

fn keyctl(
	cmd: command,
	arg2: u64,
	arg3: u64,
	arg4: u64,
	arg5: u64,
) (int | error) = {
	match (rt::keyctl(cmd, arg2, arg3, arg4, arg5)) {
	case let err: rt::errno =>
		return errno(err);
	case let n: int =>
		return n;
	};
};

// Maps a special key or keyring ID to the serial number of the key actually
// representing that feature. If it does not exist and 'create' is true, then
// the key or keyring will be created if it is appropriate to do so.
export fn get_keyring_id(key: serial, create: bool) (serial | error) = {
	return keyctl(command::GET_KEYRING_ID,
		key: u64, if (create) 1 else 0, 0, 0)?: serial;
};

// Replace the session keyring this process subscribes to with a new session
// keyring using the given name, or, given an empty string, "_ses".
export fn join_session_keyring(name: str) (serial | error) = {
	let name = if (name == "") {
		yield null;
	} else {
		yield c::fromstr(name);
	};
	defer free(name);
	return keyctl(command::JOIN_SESSION_KEYRING,
		name: uintptr: u64, 0, 0, 0)?: serial;
};

// Update a key's payload.
export fn update(id: serial, payload: []u8) (void | error) = {
	keyctl(command::UPDATE, id: u64,
		payload: *[*]u8: uintptr: u64,
		len(payload): u64, 0)?;
};

// Revoke the key with the provided ID.
export fn revoke(id: serial) (void | error) = {
	keyctl(command::REVOKE, id: u64, 0, 0, 0)?;
};

// Reads the payload from a key, returning the size of the key data. The
// provided buffer may be empty to probe the key size without reading.
export fn read(id: serial, buf: []u8) (size | error) = {
	const bufln = len(buf);
	const buf = if (len(buf) == 0) {
		yield null;
	} else {
		yield buf: *[*]u8: *opaque;
	};
	return keyctl(command::READ, id: u64,
		buf: uintptr: u64, bufln: u64, 0)?: size;
};

// Changes the user and group ownership of the key.
export fn chown(id: serial, uid: uint, gid: uint) (void | error) = {
	keyctl(command::CHOWN, id: u64, uid: u64, gid: u64, 0)?;
};

// Changes the permissions mask of the key.
export fn setperm(id: serial, perm: perm) (void | error) = {
	keyctl(command::SETPERM, id: u64, perm, 0, 0)?;
};
