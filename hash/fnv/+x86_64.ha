// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Hashes a string, returning a size key, for use in a hash map.
export fn string(s: str) size = string64(s): size;
