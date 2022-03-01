// License: MPL-2.0
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Vlad-Stefan Harbuz <vlad@vladh.net>

use bytes;

// Returns a new string duplicated from 's', but with all instances of 'needle'
// replaced with 'target'. The caller must free the return value.
export fn replace(s: str, needle: str, target: str) str = {
	return multireplace(s, (needle, target));
};

// For each tuple given by 'repls', a replacement of 's' is done like in
// [[replace]], in the order that they are passed as arguments. This function is
// nearly equivalent to calling [[replace]] multiple times, except only one new
// string is allocated. The caller must free the return value.
export fn multireplace(s: str, repls: (str, str)...) str = {
	let res = toutf8(dup(s));
	for (let i = 0z; i < len(repls); i += 1) {
		let needle = toutf8(repls[i].0);
		let target = toutf8(repls[i].1);
		let idx = 0z;
		for (true) {
			idx = match(bytes::index(res[idx..], needle)) {
			case let s: size =>
				yield s + idx;
			case void =>
				break;
			};
			delete(res[idx..idx + len(needle)]);
			insert(res[idx], target...);
			idx += len(target);
		};
	};
	return fromutf8(res);
};

@test fn replace() void = {
	assert(replace("Hello world!", "world", "there") == "Hello there!");
	assert(replace("I like dogs, dogs, birds, dogs", "dogs", "cats") ==
		"I like cats, cats, birds, cats");
	assert(replace("aaaaaa", "aa", "a") == "aaa");
	assert(replace("aaa", "a", "aa") == "aaaaaa");
	assert(replace("こんにちは", "にち", "ばん") == "こんばんは");
};

@test fn multireplace() void = {
	assert(multireplace("Hello world", ("Hello", "Greetings"),
		("world", "globe")) == "Greetings globe");
	assert(multireplace("ababa", ("a", "ba"), ("b", "a"), ("a", "c")) ==
		"cccccccc");
};
