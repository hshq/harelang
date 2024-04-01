// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use strings;

export type iterator = struct {
	cur: []u8,
	reverse: bool,
};

// Returns an [[iterator]] which yields each component of a path, moving down
// through child dirs. If the path is absolute, the first component will be
// the root. The iterator can be copied to save its state.
export fn iter(buf: *buffer) iterator = iterator {
	cur = buf.buf[..buf.end],
	reverse = false,
};

// Returns an [[iterator]] which yields each component of a path, moving up
// through parent dirs. If the path is absolute, the last component will be
// the root. The iterator can be copied to save its state.
export fn riter(buf: *buffer) iterator = iterator {
	cur = buf.buf[..buf.end],
	reverse = true,
};


// Returns the next path component from an [[iterator]], or void if none
// remain. Does not advance the iterator.
export fn peekiter(it: *iterator) (str | void) = {
	if (len(it.cur) == 0) return void;
	const (result, remaining) = split_iter(it);
	return strings::fromutf8_unsafe(result);
};

// Returns the next path component from an [[iterator]], or done if none
// remain. Advances the iterator.
export fn nextiter(it: *iterator) (str | done) = {
	if (len(it.cur) == 0) return done;
	const (result, remaining) = split_iter(it);
	it.cur = remaining;
	return strings::fromutf8_unsafe(result);
};

// helper function for nextiter and peekiter, returns (result, remaining)
fn split_iter(it: *iterator) ([]u8, []u8) = {
	if (it.reverse) {
		match (bytes::rindex(it.cur, SEP)) {
		case let sep: size =>
			let res = it.cur[sep+1..];
			if (sep == 0) {
				if (len(it.cur) == 1) {
					res = it.cur; // return the root dir
				} else {
					sep = 1; // leave the root for next
				};
			};
			return (res, it.cur[..sep]);
		case void =>
			return (it.cur, it.cur[..0]);
		};
	} else {
		match (bytes::index(it.cur, SEP)) {
		case let i: size =>
			return (it.cur[..if (i == 0) 1 else i], it.cur[i+1..]);
		case void =>
			return (it.cur, it.cur[..0]);
		};
	};
};

// Gets the remaining path from an iterator, without advancing the iterator.
export fn iterrem(it: *iterator) str = strings::fromutf8_unsafe(it.cur);

@test fn iter() void = {
	const buf = init(local("/foo/bar/baz"))!;
	let i = iter(&buf);
	assert(nextiter(&i) as str == local("/"));
	assert(nextiter(&i) as str == "foo");
	assert(nextiter(&i) as str == "bar");
	assert(nextiter(&i) as str == "baz");
	assert(nextiter(&i) is done);
	i = riter(&buf);
	assert(nextiter(&i) as str == "baz");
	assert(nextiter(&i) as str == "bar");
	assert(nextiter(&i) as str == "foo");
	assert(nextiter(&i) as str == local("/"));
	assert(nextiter(&i) is done);

	set(&buf, local("foo/bar/baz"))!;
	i = iter(&buf);
	assert(nextiter(&i) as str == "foo");
	assert(nextiter(&i) as str == "bar");
	assert(nextiter(&i) as str == "baz");
	assert(nextiter(&i) is done);
	i = riter(&buf);
	assert(nextiter(&i) as str == "baz");
	assert(nextiter(&i) as str == "bar");
	assert(nextiter(&i) as str == "foo");
	assert(nextiter(&i) is done);

	set(&buf, "foo")!;
	i = iter(&buf);
	assert(nextiter(&i) as str == "foo");
	assert(nextiter(&i) is done);
	i = riter(&buf);
	assert(nextiter(&i) as str == "foo");
	assert(nextiter(&i) is done);

	set(&buf, local("/"))!;
	i = iter(&buf);
	assert(nextiter(&i) as str == local("/"));
	assert(nextiter(&i) is done);
	i = riter(&buf);
	assert(nextiter(&i) as str == local("/"));
	assert(nextiter(&i) is done);
};
