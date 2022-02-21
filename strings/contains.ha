// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use bytes;
use encoding::utf8;

// Returns true if a string contains a rune or a sub-string.
export fn contains(haystack: str, needle: (str | rune)) bool = match (needle) {
case let s: str  =>
	yield bytes::contains(toutf8(haystack), toutf8(s));
case let r: rune =>
	yield bytes::contains(toutf8(haystack), utf8::encoderune(r));
};

@test fn contains() void = {
	assert(contains("hello world", "hello"));
	assert(contains("hello world", "world"));
	assert(contains("hello world", ""));
	assert(!contains("hello world", "foobar"));
};
