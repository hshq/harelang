// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// bcrypt uses a crappy variant of base64 with its own special alphabet and no
// padding. This file glues encoding::base64 to the bcrypt semantics.
use encoding::base64;
use errors;
use io;
use memio;

const alpha: str = "./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
const b64encoding: base64::encoding = base64::encoding { ... };

@init fn init() void = {
	base64::encoding_init(&b64encoding, alpha);
};

// Encodes a slice in the bcrypt base64 style, returning a new slice. The caller
// must free the return value.
fn b64_encode(src: []u8) []u8 = {
	let sink = memio::dynamic();
	base64::encode(&sink, &b64encoding, src)!;
	let buf = memio::buffer(&sink);
	let i = len(buf);
	for (i > 0 && buf[i - 1] == '='; i -= 1) void;
	return buf[..i];
};

// Decodes a slice in the bcrypt base64 style, returning a new slice. The
// caller must free the return value.
fn b64_decode(src: []u8) ([]u8 | errors::invalid) = {
	let src = alloc(src...);
	defer free(src);
	for (let neq = 4 - len(src) % 4; neq > 0; neq -= 1) {
		append(src, '=');
	};
	return base64::decodeslice(&b64encoding, src);
};
