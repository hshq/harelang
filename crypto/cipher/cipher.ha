// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Discards any state associated with a block or a stream cipher algorithm,
// securely erasing secret data from memory.
export fn finish(a: *block) void = {
	a.finish(a);
};
