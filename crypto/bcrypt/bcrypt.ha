// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// This implementation is not great, but neither is this algorithm. Mostly
// ported from Go.
//
// TODO: Move me into the extlib (hare-x-crypto?)
use bytes;
use crypto;
use crypto::blowfish;
use crypto::cipher;
use crypto::random;
use errors;
use fmt;
use io;
use memio;
use strconv;
use strings;

let magic: []u8 = [
	0x4f, 0x72, 0x70, 0x68,
	0x65, 0x61, 0x6e, 0x42,
	0x65, 0x68, 0x6f, 0x6c,
	0x64, 0x65, 0x72, 0x53,
	0x63, 0x72, 0x79, 0x44,
	0x6f, 0x75, 0x62, 0x74,
];

type hash = struct {
	hash: []u8,
	salt: []u8,
	cost: uint,
	major: u8,
	minor: u8,
};

// The minimum cost for a bcrypt hash.
export def MIN_COST: uint = 4;

// The maximum cost for a bcrypt hash.
export def MAX_COST: uint = 32;

// The recommended default cost for a bcrypt hash.
export def DEFAULT_COST: uint = 10;

def MAJOR: u8 = '2';
def MINOR: u8 = 'a';
def MAX_SALT_SZ: size = 16;
def MAX_CRYPTED_HASH_SZ: size = 23;
def ENCODED_SALT_SZ: size = 22;
def ENCODED_HASH_SZ: size = 31;
def MIN_HASH_SZ: size = 59;

// Hashes a password using the bcrypt algorithm. The caller must free the return
// value.
export fn generate(password: []u8, cost: uint) []u8 = {
	let salt: [MAX_SALT_SZ]u8 = [0...];
	random::buffer(salt);
	const hash = hash_password(password, salt, cost)!;
	defer finish(&hash);
	return mkhash(&hash);
};

// Compares a password against a bcrypt hash, returning true if the given
// password matches the hash, or false otherwise. [[errors::invalid]] is
// returned if the provided hash is not a valid bcrypt hash.
export fn compare(hash: []u8, password: []u8) (bool | errors::invalid) = {
	const hash = load(hash)?;
	defer finish(&hash);
	const salt = b64_decode(hash.salt)!;
	defer free(salt);
	const other = hash_password(password, salt, hash.cost)?;
	defer finish(&other);
	assert(hash.major == other.major);
	assert(hash.minor == other.minor); // TODO?
	return crypto::compare(hash.hash, other.hash);
};

fn mkhash(h: *hash) []u8 = {
	let buf = memio::dynamic();
	fmt::fprintf(&buf, "${}$", h.major: rune)!;
	if (h.minor != 0) {
		fmt::fprintf(&buf, "{}", h.minor: rune)!;
	};
	fmt::fprintf(&buf, "${:.2}$", h.cost)!;
	io::write(&buf, h.salt)!;
	io::write(&buf, h.hash)!;
	return memio::buffer(&buf);
};

fn hash_password(
	password: []u8,
	salt: []u8,
	cost: uint,
) (hash | errors::invalid) = {
	assert(cost >= MIN_COST && cost <= MAX_COST, "Invalid bcrypt cost");
	let hash = hash {
		major = MAJOR,
		minor = MINOR,
		cost = cost,
		...
	};
	hash.salt = b64_encode(salt);
	hash.hash = bcrypt(password, hash.salt, hash.cost)?;
	return hash;
};

fn load(input: []u8) (hash | errors::invalid) = {
	if (len(input) < MIN_HASH_SZ || input[0] != '$') {
		return errors::invalid;
	};
	let hash = hash { ... };

	const tok = bytes::tokenize(input[1..], ['$']);

	const major = loadtok(&tok)?;
	hash.major = strings::toutf8(major)[0];
	if (hash.major > MAJOR) {
		return errors::invalid;
	};

	const minor = loadtok(&tok)?;
	if (minor != "") {
		hash.minor = strings::toutf8(minor)[0];
	};

	const cost = loadtok(&tok)?;
	match (strconv::stou(cost)) {
	case let u: uint =>
		hash.cost = u;
	case =>
		return errors::invalid;
	};

	let data = strings::toutf8(loadtok(&tok)?);
	if (!(loadtok(&tok) is errors::invalid)) {
		return errors::invalid;
	};

	hash.salt = alloc(data[..ENCODED_SALT_SZ]...);
	hash.hash = alloc(data[ENCODED_SALT_SZ..]...);
	return hash;
};

fn loadtok(tok: *bytes::tokenizer) (str | errors::invalid) = {
	match (bytes::next_token(tok)) {
	case let b: []u8 =>
		match (strings::fromutf8(b)) {
		case let s: str =>
			return s;
		case =>
			return errors::invalid;
		};
	case void =>
		return errors::invalid;
	};
};

fn bcrypt(password: []u8, salt: []u8, cost: uint) ([]u8 | errors::invalid) = {
	let state: []u8 = alloc(magic...);
	defer free(state);

	let bf = expensive_blowfish(password, salt, cost)?;
	defer free(bf);
	for (let i = 0; i < 24; i += 8) {
		for (let j = 0; j < 64; j += 1) {
			cipher::encrypt(bf, state[i..i+8], state[i..i+8]);
		};
	};

	// Bug compat: only encode 32 bytes
	const enc = b64_encode(state[..MAX_CRYPTED_HASH_SZ]);
	return enc;
};

fn expensive_blowfish(
	key: []u8,
	salt: []u8,
	cost: uint,
) (*blowfish::state | errors::invalid) = {
	let csalt = b64_decode(salt)?;
	defer free(csalt);

	// Bug compat: OpenBSD does this cool thing where it treats the string's
	// trailing NUL as part of the key
	let ckey = alloc(key...);
	append(ckey, 0);
	defer free(ckey);

	const bf = alloc(blowfish::new());
	blowfish::init_salt(bf, ckey, csalt);

	let rounds: u64 = 1u64 << cost;
	for (let i = 0u64; i < rounds; i += 1) {
		blowfish::init(bf, ckey);
		blowfish::init(bf, csalt);
	};

	return bf;
};

fn finish(hash: *hash) void = {
	free(hash.hash);
	free(hash.salt);
};
