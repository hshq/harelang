// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;

// All error types that can be returned from [[poll]].
export type error = !errors::error;

// Converts an [[error]] into a human-friendly string representation.
export fn strerror(err: error) const str = errors::strerror(err);
