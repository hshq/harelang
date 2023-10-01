// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use strings;

// Add a prefix to a buffer. The buffer will be modified, and it will
// remain normalized, so any ".." components in the original buffer may be
// collapsed.
export fn prepend(buf: *buffer, prefix: str...) (str | error) = {
	static let tmp = buffer { ... };
	tmp = *buf;
	set(buf, prefix...)?;
	return push(buf, string(&tmp));
};

// Returns a buffer without a prefix. The prefix is normalized before
// processing, and this function will return [[too_long]] if the prefix is
// longer than [[MAX]]. If the prefix is not present, returns [[not_prefix]].
// The resulting path will always be relative.
//
// This function does not modify the buffer. See [[popprefix]].
export fn trimprefix(buf: *buffer, prefix: str) (str | error) = {
	const start = splitprefix(buf, prefix)?;
	if (start == buf.end) return ".";
	return strings::fromutf8_unsafe(buf.buf[start..buf.end]);
};

// Equivalent to [[trimprefix]], but modifies the buffer in the process.
export fn popprefix(buf: *buffer, prefix: str) (str | error) = {
	const start = splitprefix(buf, prefix)?;
	static delete(buf.buf[..][..start]);
	buf.end -= start;
	return string(buf);
};

// helper function for trimprefix and popprefix, returns the new
// start of the buffer, or an error.
fn splitprefix(buf: *buffer, prefix: str) (size | error) = {
	let pref = init(prefix)?;
	if (pref.end == 0) {
		if (abs(buf)) return not_prefix;
	} else if (pref.end < buf.end && pref.buf[pref.end-1] != SEP) {
		pref.buf[pref.end] = SEP;
		pref.end += 1;
	};
	if (bytes::hasprefix(buf.buf[..buf.end], pref.buf[..pref.end])) {
		return pref.end;
	} else {
		return not_prefix;
	};
};

@test fn prepend() void = {
	const buf = init("a")!;

	// relative
	assert(prepend(&buf, "apple")! == local("apple/a"));
	assert(popprefix(&buf, "b") is error);
	assert(popprefix(&buf, "appl") is error);
	assert(popprefix(&buf, local("/")) is error);
	assert(popprefix(&buf, ".")! == local("apple/a"));
	assert(popprefix(&buf, "apple")! == "a");
	assert(popprefix(&buf, "a")! == ".");

	// absolute
	assert(prepend(&buf, local("/apple/a"))! == local("/apple/a"));
	assert(popprefix(&buf, local("/b")) is error);
	assert(popprefix(&buf, local("/appl")) is error);
	assert(popprefix(&buf, ".") is error);
	assert(popprefix(&buf, local("/"))! == local("apple/a"));
	assert(prepend(&buf, local("/"))! == local("/apple/a"));
	assert(popprefix(&buf, local("/apple/a"))! == ".");
};
