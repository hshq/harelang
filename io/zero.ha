// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;

const _zero_vt: vtable = vtable {
	reader = &zero_read,
	writer = &empty_write,
	...
};

const _zero: stream = &_zero_vt;

// A [[stream]] which always reads zeroes and discards any writes.
export const zero: *stream = &_zero;

fn zero_read(s: *stream, buf: []u8) (size | EOF | error) = {
	bytes::zero(buf);
	return len(buf);
};
