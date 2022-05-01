// License: MPL-2.0
// (c) 2022 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
use bytes;

const _zero_vt: vtable = vtable {
	reader = &zero_read,
	writer = &empty_write,
	...
};

const _zero: stream = &_zero_vt;

// A [[stream]] which always reads zereos and discards any writes.
export const zero: *stream = &_zero;

fn zero_read(s: *stream, buf: []u8) (size | EOF | error) = {
	bytes::zero(buf);
	return len(buf);
};
