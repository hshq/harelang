// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use crypto::argon2;
use errors;

// Given a password, derive a key. Given the same password, salt, memory, and
// passes, this function will always produce the same key. This function is
// designed to derive cryptographic keys from user-provided passwords, or to
// verify a password for user logins.
//
// The user provides a buffer for the key to be written to via the 'dest'
// parameter. The minimum supported length for this buffer is 4 bytes, and the
// recommended length is 32 bytes.
//
// The salt parameter should be randomly generated, stored alongside the key,
// and used in subsequent calls to produce the same key. It must be at least 8
// bytes, but 16 bytes is recommended. Use [[crypto::random::]] to generate a
// different salt for each key.
//
// The 'mem' and 'passes' functions are provided to tune the behavior of this
// algorithm. It is designed to be computationally expensive, and you must
// adjust these figures to suit your hardware and use-case. If you provide a u32
// for 'mem', the algorithm will dynamically allocate that many kilobytes of
// working memory. To allocate this memory yourself, provide a []u64 instead.
// The number of passes controls the amount of time spent generating the key,
// higher numbers take longer.
//
// To identify ideal values for these parameters, start with 100000 for 'mem'
// (100 MiB) and 0 for 'passes'. If it takes too long, reduce the amount of
// memory, and if it does not take long enough, increase the amount of memory.
// If you have reached the maximum amount of memory you are able to use,
// increase passes.
//
// The current implementation of this function uses argon2id version 1.3 with the
// provided number of memory blocks, passes equal to passes + 3, and parallelism
// set to one.
export fn derivekey(
	dest: []u8,
	salt: []u8,
	password: []u8,
	mem: (u32 | []u64),
	passes: u32,
) (void | errors::nomem) = {
	const config = argon2::conf {
		mem = mem,
		parallel = 1,
		passes = passes + 3,
		version = argon2::VERSION,
		...
	};
	return argon2::argon2id(dest, password, salt, &config);
};
