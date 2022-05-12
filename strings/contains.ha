// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2022 Vlad-Stefan Harbuz <vlad@vladh.net>
use bytes;
use encoding::utf8;

// Returns true if a string contains a rune or a sub-string, multiple of which
// can be given.
export fn contains(haystack: str, needles: (str | rune)...) bool = {
	for (let i = 0z; i < len(needles); i += 1) {
		const matched = match (needles[i]) {
		case let s: str =>
			yield bytes::contains(toutf8(haystack),
				toutf8(s));
		case let r: rune =>
			yield bytes::contains(toutf8(haystack),
				utf8::encoderune(r));
		};
		if (matched) {
			return true;
		};
	};
	return false;
};

@test fn contains() void = {
	assert(contains("hello world", "hello"));
	assert(contains("hello world", 'h'));
	assert(!contains("hello world", 'x'));
	assert(contains("hello world", "world"));
	assert(contains("hello world", ""));
	assert(!contains("hello world", "foobar"));
	assert(contains("hello world", "foobar", "hello", "bar"));
	assert(!contains("hello world", "foobar", "foo", "bar"));
	assert(contains("hello world", 'h', "foo", "bar"));
	assert(!contains("hello world", 'x', "foo", "bar"));
};
