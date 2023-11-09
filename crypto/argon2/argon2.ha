// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021-2022 Armin Preiml <apreiml@strohwolke.at>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
use bytes;
use crypto::blake2b;
use crypto::math;
use endian;
use errors::{nomem};
use hash;
use io;
use memio;
use types;

// Latest version of argon2 supported by this implementation (1.3).
export def VERSION: u8 = 0x13;

// Number of u64 elements of one block.
export def BLOCKSZ: u32 = 128;

def SLICES: size = 4;

type block64 = [BLOCKSZ]u64;

const zeroblock: block64 = [0...];

type mode = enum {
	D = 0,
	I = 1,
	ID = 2,
};

// This type provides configuration options for the argon2 algorithm. Most users
// will find [[default_conf]] or [[low_mem_conf]] suitable for their needs
// without providing a custom configuration. If writing a custom configuration,
// consult the RFC for advice on selecting suitable values for your use-case.
//
// 'parallel' specifies the number of parallel processes. 'pass' configures the
// number of iterations. Both values must be at least one. Note: the Hare
// implementation of argon2 does not process hashes in parallel, though it will
// still compute the correct hash if this value is greater than one.
//
// 'version' specifies the version of the argon2 function. The implementation
// currently only supports version 1.3. Use [[VERSION]] here.
//
// 'secret' and 'data' are optional byte arrays that are applied to the initial
// state. Consult the RFC for details.
//
// The 'mem' parameter is used to configure working memory used during the
// computation. The argon2 algorithm requires a large amount of memory to
// compute hashes. If 'mem' set to a u32, it is interpreted as the desired
// number of 1024-byte blocks the implementation shall allocate for you. If the
// caller wants to manage the allocation itself, provide a []u8 instead. The
// length of this slice must be at least 8 times the value of 'parallel' in
// blocks, and must be a multiple of [[BLOCKSZ]]. To have the implementation
// allocate 64 KiB, set 'mem' to 64. To use the same amount of caller-provided
// memory, provide a slice of length 64 * [[BLOCKSZ]].
export type conf = struct {
	mem: (u32 | []u64),
	parallel: u32,
	passes: u32,
	version: u8,
	secret: []u8,
	data: []u8
};

// The default recommended configuration for most use cases. This configuration
// uses 2 GiB of working memory. A 16-byte 'salt' and 32-byte 'dest' parameter
// is recommended in combination with this configuration.
export const default_conf: conf = conf {
	mem = 2 * 1024 * 1024,
	passes = 1,
	parallel = 4,
	version = 0x13,
	...
};

// The default recommended configuration for memory-constrained use cases. This
// configuration uses 64 MiB of working memory. A 16-byte 'salt' and 32-byte
// 'dest' parameter is recommended in combination with this configuration.
export const low_mem_conf: conf = conf {
	mem = 64 * 1024,
	passes = 3,
	parallel = 4,
	version = 0x13,
	...
};

type context = struct {
	mode: mode,
	cols: size,
	rows: size,
	sliceblocks: size,
	mem: []u64,
	pass: u32,
	seedsinit: block64,
	seedblock: block64,
};

// Computes an argon2d hash, writing the digest to 'dest'. A 'salt' length of 16
// bytes is recommended, and 8 bytes is the minimum. A 'dest' length of 32 bytes
// is recommended, and 4 bytes is the minimum.
//
// The argon2d mode uses data-dependent memory access and is suitable for
// applications with no threats of side-channel timing attacks.
export fn argon2d(
	dest: []u8,
	password: []u8,
	salt: []u8,
	cfg: *conf,
) (void | nomem) = {
	return argon2(dest, password, salt, cfg, mode::D);
};

// Computes an argon2i hash, writing the digest to 'dest'. A 'salt' length of 16
// bytes is recommended, and 8 bytes is the minimum. A 'dest' length of 32 bytes
// is recommended, and 4 bytes is the minimum.
//
// The argon2i mode uses data-independent memory access and is suitable for
// password hashing and key derivation. It makes more passes over memory to
// protect from trade-off attacks.
export fn argon2i(
	dest: []u8,
	password: []u8,
	salt: []u8,
	cfg: *conf,
) (void | nomem) = {
	return argon2(dest, password, salt, cfg, mode::I);
};

// Computes an argon2id hash, writing the digest to 'dest'. A 'salt' length of
// 16 bytes is recommended, and 8 bytes is the minimum. A 'dest' length of 32
// bytes is recommended, and 4 bytes is the minimum.
//
// The argon2id mode works by using argon2i for the first half of the first pass
// and argon2d further on. It provides therefore protection from side-channel
// attacks and brute-force cost savings due to memory trade-offs.
//
// If you are unsure which variant to use, argon2id is recommended.
export fn argon2id(
	dest: []u8,
	password: []u8,
	salt: []u8,
	cfg: *conf,
) (void | nomem) = {
	return argon2(dest, password, salt, cfg, mode::ID);
};

fn argon2(
	dest: []u8,
	password: []u8,
	salt: []u8,
	cfg: *conf,
	mode: mode,
) (void | nomem) = {
	assert(endian::host == &endian::little, "TODO big endian support");

	assert(len(dest) >= 4 && len(dest) <= types::U32_MAX);
	assert(len(password) <= types::U32_MAX);
	assert(len(salt) >= 8 && len(salt) <= types::U32_MAX);
	assert(cfg.parallel >= 1);
	assert(cfg.passes >= 1);
	assert(len(cfg.secret) <= types::U32_MAX);
	assert(len(cfg.data) <= types::U32_MAX);

	let initmemsize = 0u32;
	let mem: []u64 = match (cfg.mem) {
	case let mem: []u64 =>
		assert(len(mem) >= 8 * cfg.parallel * BLOCKSZ
			&& len(mem) % BLOCKSZ == 0
			&& len(mem) / BLOCKSZ <= types::U32_MAX);
		initmemsize = (len(mem) / BLOCKSZ): u32;

		// round down memory to nearest multiple of 4 times parallel
		const memsize = len(mem) - len(mem)
			% (4 * cfg.parallel * BLOCKSZ);
		yield mem[..memsize];
	case let memsize: u32 =>
		assert(memsize >= 8 * cfg.parallel
			&& memsize <= types::U32_MAX);

		initmemsize = memsize;
		const memsize = memsize - memsize % (4 * cfg.parallel);
		yield alloc([0...], memsize * BLOCKSZ): []u64;
	};

	let h0: [64]u8 = [0...];
	inithash(&h0, len(dest): u32, password, salt, cfg, mode, initmemsize);

	const memsize = (len(mem) / BLOCKSZ): u32;
	const cols = 4 * (memsize / (4 * cfg.parallel));
	let ctx = context {
		rows = cfg.parallel,
		cols = cols,
		sliceblocks = cols / 4,
		pass = 0,
		mem = mem,
		mode = mode,
		seedsinit = [0...],
		seedblock = [0...],
		...
	};

	// hash first and second blocks of each row
	for (let i = 0z; i < ctx.rows; i += 1) {
		let src: [72]u8 = [0...];
		src[..64] = h0[..];

		endian::leputu32(src[64..68], 0);
		endian::leputu32(src[68..], i: u32);
		varhash(blocku8(&ctx, i, 0), src);

		endian::leputu32(src[64..68], 1);
		endian::leputu32(src[68..], i: u32);
		varhash(blocku8(&ctx, i, 1), src);
	};

	// process segments
	for (ctx.pass < cfg.passes; ctx.pass += 1) {
		for (let s = 0z; s < SLICES; s += 1) {
			for (let i = 0z; i < ctx.rows; i += 1) {
				segproc(cfg, &ctx, i, s);
			};
		};
	};

	// final hash
	let b = blocku8(&ctx, 0, ctx.cols - 1);
	for (let i = 1z; i < ctx.rows; i += 1) {
		math::xor(b, b, blocku8(&ctx, i, ctx.cols - 1));
	};

	varhash(dest, b);

	bytes::zero(h0);
	bytes::zero((ctx.mem: *[*]u8)[..len(ctx.mem) * size(u64)]);

	if (cfg.mem is u32) {
		// mem was allocated internally
		free(ctx.mem);
	};
};

fn block(ctx: *context, i: size, j: size) []u64 = {
	let index = (ctx.cols * i + j) * BLOCKSZ;
	return ctx.mem[index..index + BLOCKSZ];
};

fn blocku8(ctx: *context, i: size, j: size) []u8 = {
	return (block(ctx, i, j): *[*]u8)[..BLOCKSZ * size(u64)];
};

fn refblock(cfg: *conf, ctx: *context, seed: u64, i: size, j: size) []u64 = {
	const segstart = (j - (j % ctx.sliceblocks)) / ctx.sliceblocks;
	const index = j % ctx.sliceblocks;

	const l: size = if (segstart == 0 && ctx.pass == 0) {
		yield i;
	} else {
		yield (seed >> 32) % cfg.parallel;
	};

	let poolstart: u64 = ((segstart + 1) % SLICES) * ctx.sliceblocks;
	let poolsize: u64 = 3 * ctx.sliceblocks;

	if (i == l) {
		poolsize += index;
	};

	if (ctx.pass == 0) {
		poolstart = 0;
		poolsize = segstart * ctx.sliceblocks;
		if (segstart == 0 || i == l) {
			poolsize += index;
		};
	};

	if (index == 0 || i == l) {
		poolsize -= 1;
	};

	const j1: u64 = seed & 0xffffffff;
	const x: u64 = (j1 * j1) >> 32;
	const y: u64 = (poolsize * x) >> 32;
	const z: u64 = (poolstart + poolsize - (y+1)) % ctx.cols: u64;

	return block(ctx, l: size, z: size);
};

fn inithash(
	dest: *[64]u8,
	taglen: u32,
	password: []u8,
	salt: []u8,
	cfg: *conf,
	mode: mode,
	memsize: u32,
) void = {
	let u32buf: [4]u8 = [0...];
	let h = blake2b::blake2b([], 64);
	defer hash::close(&h);

	hash_leputu32(&h, cfg.parallel);
	hash_leputu32(&h, taglen);
	hash_leputu32(&h, memsize);
	hash_leputu32(&h, cfg.passes);
	hash_leputu32(&h, cfg.version);
	hash_leputu32(&h, mode: u32);
	hash_leputu32(&h, len(password): u32);
	hash::write(&h, password);

	hash_leputu32(&h, len(salt): u32);
	hash::write(&h, salt);

	hash_leputu32(&h, len(cfg.secret): u32);
	hash::write(&h, cfg.secret);

	hash_leputu32(&h, len(cfg.data): u32);
	hash::write(&h, cfg.data);

	hash::sum(&h, dest[..]);
};

fn hash_leputu32(h: *hash::hash, u: u32) void = {
	let buf: [4]u8 = [0...];
	endian::leputu32(buf, u);
	hash::write(h, buf[..]);
};

// The variable hash function H'
fn varhash(dest: []u8, block: []u8) void = {
	let u32buf: [4]u8 = [0...];

	if (len(dest) <= 64) {
		let h = blake2b::blake2b([], len(dest));
		defer hash::close(&h);
		hash_leputu32(&h, len(dest): u32);
		hash::write(&h, block);
		hash::sum(&h, dest);
		return;
	};

	// TODO this may be replaced with a constant time divceil in future to
	// avoid leaking the dest len.
	const r = divceil(len(dest): u32, 32) - 2;
	let v: [64]u8 = [0...];

	let destbuf = memio::fixed(dest);

	let h = blake2b::blake2b([], 64);
	hash_leputu32(&h, len(dest): u32);
	hash::write(&h, block);
	hash::sum(&h, v[..]);
	hash::close(&h);

	io::writeall(&destbuf, v[..32])!;

	for (let i = 1z; i < r; i += 1) {
		let h = blake2b::blake2b([], 64);
		hash::write(&h, v[..]);
		hash::sum(&h, v[..]);
		hash::close(&h);
		io::writeall(&destbuf, v[..32])!;
	};

	const remainder = len(dest) - 32 * r;
	let hend = blake2b::blake2b([], remainder);
	defer hash::close(&hend);
	hash::write(&hend, v[..]);
	hash::sum(&hend, v[..remainder]);
	io::writeall(&destbuf, v[..remainder])!;
};

fn divceil(dividend: u32, divisor: u32) u32 = {
	let result = dividend / divisor;
	if (dividend % divisor > 0) {
		result += 1;
	};
	return result;
};

fn xorblock(dest: []u64, x: []u64, y: []u64) void = {
	for (let i = 0z; i < len(dest); i += 1) {
		dest[i] = x[i] ^ y[i];
	};
};

fn segproc(cfg: *conf, ctx: *context, i: size, slice: size) void = {
	const init = switch (ctx.mode) {
	case mode::I =>
		yield true;
	case mode::ID =>
		yield ctx.pass == 0 && slice < 2;
	case mode::D =>
		yield false;
	};
	if (init) {
		ctx.seedsinit[0] = ctx.pass;
		ctx.seedsinit[1] = i;
		ctx.seedsinit[2] = slice;
		ctx.seedsinit[3] = len(ctx.mem) / BLOCKSZ;
		ctx.seedsinit[4] = cfg.passes;
		ctx.seedsinit[5] = ctx.mode: u64;
		ctx.seedsinit[6] = 0;

		if (ctx.pass == 0 && slice == 0) {
			ctx.seedsinit[6] += 1;
			compress(ctx.seedblock, ctx.seedsinit, zeroblock,
				false);
			compress(ctx.seedblock, ctx.seedblock, zeroblock,
				false);
		};
	};

	for (let b = 0z; b < ctx.sliceblocks; b += 1) {
		const j = slice * ctx.sliceblocks + b;
		if (ctx.pass == 0 && j < 2) {
			continue;
		};

		const dmodeseed = switch (ctx.mode) {
		case mode::D =>
			yield true;
		case mode::ID =>
			yield ctx.pass > 0 || slice > 1;
		case mode::I =>
			yield false;
		};

		const pj = if (j == 0) ctx.cols - 1 else j - 1;
		let prev = block(ctx, i, pj);

		const seed: u64 = if (dmodeseed) {
			yield prev[0];
		} else {
			if (b % BLOCKSZ == 0) {
				ctx.seedsinit[6] += 1;
				compress(ctx.seedblock, ctx.seedsinit,
					zeroblock, false);
				compress(ctx.seedblock, ctx.seedblock,
					zeroblock, false);
			};
			yield ctx.seedblock[b % BLOCKSZ];
		};

		let ref = refblock(cfg, ctx, seed, i, j);
		compress(block(ctx, i, j), prev, ref, ctx.pass > 0);
	};
};

fn compress(dest: []u64, x: []u64, y: []u64, xor: bool) void = {
	let r: block64 = [0...];
	xorblock(r, x, y);

	let z: block64 = [0...];
	z[..] = r[..];

	for (let i = 0z; i < 128; i += 16) {
		perm(&z[i], &z[i + 1], &z[i + 2], &z[i + 3], &z[i + 4],
			&z[i + 5], &z[i + 6], &z[i + 7], &z[i + 8], &z[i + 9],
			&z[i + 10], &z[i + 11], &z[i + 12], &z[i + 13],
			&z[i + 14], &z[i + 15]);
	};

	for (let i = 0z; i < 16; i += 2) {
		perm(&z[i], &z[i + 1], &z[i + 16], &z[i + 17], &z[i + 32],
			&z[i + 33], &z[i + 48], &z[i + 49], &z[i + 64],
			&z[i + 65], &z[i + 80], &z[i + 81], &z[i + 96],
			&z[i + 97], &z[i + 112], &z[i + 113]);
	};

	if (xor) {
		xorblock(r, r, dest);
	};

	xorblock(dest, z, r);
};

fn perm(
	x0: *u64,
	x1: *u64,
	x2: *u64,
	x3: *u64,
	x4: *u64,
	x5: *u64,
	x6: *u64,
	x7: *u64,
	x8: *u64,
	x9: *u64,
	x10: *u64,
	x11: *u64,
	x12: *u64,
	x13: *u64,
	x14: *u64,
	x15: *u64,
) void = {
	mix(x0, x4, x8, x12);
	mix(x1, x5, x9, x13);
	mix(x2, x6, x10, x14);
	mix(x3, x7, x11, x15);

	mix(x0, x5, x10, x15);
	mix(x1, x6, x11, x12);
	mix(x2, x7, x8, x13);
	mix(x3, x4, x9, x14);
};

fn mix(a: *u64, b: *u64, c: *u64, d: *u64) void = {
	*a = *a + *b + 2 * (*a & 0xffffffff) * (*b & 0xffffffff);
	*d = math::rotr64(*d ^ *a, 32);
	*c = *c + *d + 2 * (*c & 0xffffffff) * (*d & 0xffffffff);
	*b = math::rotr64(*b ^ *c, 24);

	*a = *a + *b + 2 * (*a & 0xffffffff) * (*b & 0xffffffff);
	*d = math::rotr64(*d ^ *a, 16);
	*c = *c + *d + 2 * (*c & 0xffffffff) * (*d & 0xffffffff);
	*b = math::rotr64(*b ^ *c, 63);
};
