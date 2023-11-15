// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use types::c;

// A key ID.
export type serial = i32;

// Returned when a desired key was not found.
export type nokey = !void;

// A tagged union of all possible error types.
export type error = !(nokey | errors::error);

// The caller's thread-specific keyring.
export def THREAD_KEYRING: serial = -1;

// The caller's process-specific keyring.
export def PROCESS_KEYRING: serial = -2;

// The caller's session-specific keyring.
export def SESSION_KEYRING: serial = -3;

// The caller's UID-specific keyring.
export def USER_KEYRING: serial = -4;

// The caller's UID-session keyring.
export def USER_SESSION_KEYRING: serial = -5;

// The caller's GID-specific keyring.
export def GROUP_KEYRING: serial = -6;

// The caller's GID-session keyring.
export def REQKEY_AUTH_KEY: serial = -7;

// The Key ID for the [[reqkey]] destination keyring.
export def REQUESTOR_KEYRING: serial = -8;

// request-key default keyrings
export type reqkey = enum int {
	NO_CHANGE = -1,
	DEFAULT = 0,
	THREAD_KEYRING = 1,
	PROCESS_KEYRING = 2,
	SESSION_KEYRING = 3,
	USER_KEYRING = 4,
	USER_SESSION_KEYRING = 5,
	GROUP_KEYRING = 6,
	REQUESTOR_KEYRING = 7,
};

// keyctl commands
export type command = enum int {
	GET_KEYRING_ID = 0,
	JOIN_SESSION_KEYRING = 1,
	UPDATE = 2,
	REVOKE = 3,
	CHOWN = 4,
	SETPERM = 5,
	DESCRIBE = 6,
	CLEAR = 7,
	LINK = 8,
	UNLINK = 9,
	SEARCH = 10,
	READ = 11,
	INSTANTIATE = 12,
	NEGATE = 13,
	SET_REQKEY_KEYRING = 14,
	SET_TIMEOUT = 15,
	ASSUME_AUTHORITY = 16,
	GET_SECURITY = 17,
	SESSION_TO_PARENT = 18,
	REJECT = 19,
	INSTANTIATE_IOV = 20,
	INVALIDATE = 21,
	GET_PERSISTENT = 22,
	DH_COMPUTE = 23,
	PKEY_QUERY = 24,
	PKEY_ENCRYPT = 25,
	PKEY_DECRYPT = 26,
	PKEY_SIGN = 27,
	PKEY_VERIFY = 28,
	RESTRICT_KEYRING = 29,
	MOVE = 30,
	CAPABILITIES = 31,
	WATCH_KEY = 32,
};

// Input for [[command::DH_COMPUTE]]
export type dh_params = struct {
	private: i32,
	prime: i32,
	base: i32,
};

// Output for [[command::DH_COMPUTE]]
export type kdf_params = struct {
	hashname: *c::char,
	otherinfo: *c::char,
	otherinfolen: u32,
	__spare: [8]u32,
};

export type support = enum u32 {
	SUPPORTS_ENCRYPT = 0x01,
	SUPPORTS_DECRYPT = 0x02,
	SUPPORTS_SIGN = 0x04,
	SUPPORTS_VERIFY = 0x08,
};

export type pkey_query = struct {
	supported_ops: u32,
	key_size: u32,
	max_data_size: u16,
	max_sig_size: u16,
	max_enc_size: u16,
	max_dec_size: u16,
	__spare: [10]u32,
};

export type pkey_params = struct {
	key_id: i32,
	in_len: u32,
	union {
		out_len: u32,
		in2_len: u32,
	},
	__spare: [7]u32,
};

export type caps = enum u8 {
	CAPS0_CAPABILITIES = 0x01,
	CAPS0_PERSISTENT_KEYRINGS = 0x02,
	CAPS0_DIFFIE_HELLMAN = 0x04,
	CAPS0_PUBLIC_KEY = 0x08,
	CAPS0_BIG_KEY = 0x10,
	CAPS0_INVALIDATE = 0x20,
	CAPS0_RESTRICT_KEYRING = 0x40,
	CAPS0_MOVE = 0x80,
	CAPS1_NS_KEYRING_NAME = 0x01,
	CAPS1_NS_KEY_TAG = 0x02,
	CAPS1_NOTIFICATIONS = 0x04,
};

export type perm = enum u32 {
	KEY_OTH_VIEW = 0x01,
	KEY_OTH_READ = 0x02,
	KEY_OTH_WRITE = 0x04,
	KEY_OTH_SEARCH = 0x08,
	KEY_OTH_LINK = 0x10,
	KEY_OTH_SETATTR = 0x20,
	KEY_OTH_ALL = 0x3f,

	KEY_GRP_VIEW = 0x0100,
	KEY_GRP_READ = 0x0200,
	KEY_GRP_WRITE = 0x0400,
	KEY_GRP_SEARCH = 0x0800,
	KEY_GRP_LINK = 0x1000,
	KEY_GRP_SETATTR = 0x2000,
	KEY_GRP_ALL = 0x3f00,

	KEY_USR_VIEW = 0x010000,
	KEY_USR_READ = 0x020000,
	KEY_USR_WRITE = 0x040000,
	KEY_USR_SEARCH = 0x080000,
	KEY_USR_LINK = 0x100000,
	KEY_USR_SETATTR = 0x200000,
	KEY_USR_ALL = 0x3f0000,

	KEY_POS_VIEW = 0x01000000,
	KEY_POS_READ = 0x02000000,
	KEY_POS_WRITE = 0x04000000,
	KEY_POS_SEARCH = 0x08000000,
	KEY_POS_LINK = 0x10000000,
	KEY_POS_SETATTR = 0x20000000,
	KEY_POS_ALL = 0x3f000000,
};

// Converts an [[error]] into a human-friendly string.
export fn strerror(err: error) const str = match (err) {
case nokey =>
	return "A desired key was not found";
case let err: errors::error =>
	return errors::strerror(err);
};
