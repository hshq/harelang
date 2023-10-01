// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// This function type is used when sorting and searching. Given two pointers to
// values, a function of this type should return an integer less than, equal to,
// or greater than zero if the first argument is, respectively, less than, equal
// to, or greater than the second argument.
export type cmpfunc = fn(a: const *opaque, b: const *opaque) int;
