// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Returned when more data is needed, i.e. when an incomplete UTF-8 sequence is
// encountered.
export type more = void;

// Returned when an invalid UTF-8 sequence was found.
export type invalid = !void;

// Converts an error into a human-friendly string.
export fn strerror(err: invalid) str = "Invalid UTF-8";
