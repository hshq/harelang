// License: MPL-2.0
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Vlad-Stefan Harbuz <vlad@vladh.net>

use bytes;

// Replaces all instances of 'needle' with 'target' in 's'.
// The caller must free the return value.
export fn replace(s: str, needle: str, target: str) str = {
	let res = toutf8(dup(s));
	let needle = toutf8(needle);
	let target = toutf8(target);
	let match_idx = 0z;
	for (true) {
		match_idx = match(bytes::index(res[match_idx..], needle)) {
		case let s: size =>
			yield s - match_idx;
		case void =>
			break;
		};
		delete(res[match_idx..match_idx + len(needle)]);
		insert(res[match_idx], target...);
		match_idx += len(needle);
	};
	return fromutf8(res);
};

@test fn replace() void = {
	assert(replace("Hello world!", "world", "there") == "Hello there!");
	assert(replace("I like dogs, dogs, birds, dogs", "dogs", "cats") ==
		"I like cats, cats, birds, cats");
	assert(replace("aaaaaa", "aa", "a") == "aaa");
	assert(replace("aaaaaa", "a", "aa") == "aaaaaa");
	assert(replace("こんにちは", "にち", "ばん") == "こんばんは");
};
