use endian;
use hash;
use io;
use strings;

def prime32: u32 = 16777619;
def prime64: u64 = 1099511628211;
def basis32: u32 = 2166136261;
def basis64: u64 = 14695981039346656037;

export type state32 = struct {
	hash::hash,
	v: u32,
};

export type state64 = struct {
	hash::hash,
	v: u64,
};

// Creates a [[hash::hash]] which computes the FNV-1 32-bit hash function. This
// hash does not allocate any state, so you do not need to call [[hash::close]]
// when you're done with it.
//
// Unless you have a reason to use this, [[fnv32a]] is recommended instead.
export fn fnv32() state32 = state32 {
	writer = &fnv32_write,
	closer = &fnv_close,
	sum = &fnv32_sum,
	reset = &fnv32_reset,
	sz = 4,
	v = basis32,
};

// Creates a [[hash::hash]] which computes the FNV-1a 32-bit hash function. This
// hash does not allocate any state, so you do not need to call [[hash::close]]
// when you're done with it.
export fn fnv32a() state32 = state32 {
	writer = &fnv32a_write,
	closer = &fnv_close,
	sum = &fnv32_sum,
	reset = &fnv32_reset,
	sz = 4,
	v = basis32,
};

// Creates a [[hash::hash]] which computes the FNV-1 64-bit hash function. This
// hash does not allocate any state, so you do not need to call [[hash::close]]
// when you're done with it.
//
// Unless you have a reason to use this, [[fnv64a]] is recommended instead.
export fn fnv64() state64 = state64 {
	writer = &fnv64_write,
	closer = &fnv_close,
	sum = &fnv64_sum,
	reset = &fnv64_reset,
	sz = 8,
	v = basis64,
};

// Creates a [[hash::hash]] which computes the FNV-1a 64-bit hash function. This
// hash does not allocate any state, so you do not need to call [[hash::close]]
// when you're done with it.
export fn fnv64a() state64 = state64 {
	writer = &fnv64a_write,
	closer = &fnv_close,
	sum = &fnv64_sum,
	reset = &fnv64_reset,
	sz = 8,
	v = basis64,
};

fn fnv_close(s: *io::stream) void = void;

fn fnv32_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *state32;
	for (let i = 0z; i < len(buf); i += 1) {
		s.v *= prime32;
		s.v ^= buf[i];
	};
	return len(buf);
};

fn fnv32a_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *state32;
	for (let i = 0z; i < len(buf); i += 1) {
		s.v ^= buf[i];
		s.v *= prime32;
	};
	return len(buf);
};

fn fnv32_reset(h: *hash::hash) void = {
	let h = h: *state32;
	h.v = basis32;
};

fn fnv32_sum(h: *hash::hash, buf: []u8) void = {
	let h = h: *state32;
	endian::host.putu32(buf, h.v);
};

fn fnv64_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *state64;
	for (let i = 0z; i < len(buf); i += 1) {
		s.v *= prime64;
		s.v ^= buf[i];
	};
	return len(buf);
};

fn fnv64a_write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *state64;
	for (let i = 0z; i < len(buf); i += 1) {
		s.v ^= buf[i];
		s.v *= prime64;
	};
	return len(buf);
};

fn fnv64_reset(h: *hash::hash) void = {
	let h = h: *state64;
	h.v = basis64;
};

fn fnv64_sum(h: *hash::hash, buf: []u8) void = {
	let h = h: *state64;
	endian::host.putu64(buf, h.v);
};

// Returns the sum of a 32-bit FNV hash.
export fn sum32(h: *hash::hash) u32 = {
	assert(h.reset == &fnv32_reset);
	let h = h: *state32;
	return h.v;
};

// Returns the sum of a 64-bit FNV hash.
export fn sum64(h: *hash::hash) u64 = {
	assert(h.reset == &fnv64_reset);
	let h = h: *state64;
	return h.v;
};

@test fn fnv32() void = {
	// TODO: Expand these tests
	// I am too tired
	const vectors: [_](str, u32) = [
		("", 2166136261),
		("hello world", 1418570095),
		("Hare is a cool language", 2663852071),
		("'UNIX was not designed to stop its users from doing stupid things, as that would also stop them from doing clever things' - Doug Gwyn", 1203174417),
		("'Life is too short to run proprietary software' - Bdale Garbee", 493463614),
		("'The central enemy of reliability is complexity.' - Geer et al", 3263526736),
		("'A language that doesn’t have everything is actually easier to program in than some that do.' - Dennis Ritchie", 3069348265),
	];

	let hash = fnv32();
	let s: [4]u8 = [0...];

	for (let i = 0z; i < len(vectors); i += 1) {
		let vec = vectors[i];

		hash::reset(&hash);
		hash::write(&hash, strings::toutf8(vec.0));
		hash::sum(&hash, s);

		assert(endian::host.getu32(s) == vec.1);
		assert(sum32(&hash) == vec.1);
	};
};
