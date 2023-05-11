// License: MPL-2.0
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Vlad-Stefan Harbuz <vlad@vladh.net>

use bytes;

// Returns a new string duplicated from 's', but with all instances of 'needle'
// replaced with 'target'. The caller must free the return value.
export fn replace(s: str, needle: str, target: str) str = {
	return multireplace(s, (needle, target));
};

// Performs a replacement in 's' of each tuple given by 'repls'. Replacement 
// occurs in a single pass of 's', and works like in [[replace]], except that 
// replacement pairs found earlier in 'repls' will take precedence over later 
// ones. For example:
//
// 	assert(multireplace("hello there", ("e", "a"), ("a", "x"), ("ell", "eww")) == "hallo thara");
// 	assert(multireplace("hello there", ("ell", "eww"), ("e", "a")) == "hewwo thara");
//
// The caller must free the return value.
export fn multireplace(s: str, repls: (str, str)...) str = {
	let replb: []([]u8, []u8) = alloc([], len(repls));
	defer free(replb);
	for (let i = 0z; i < len(repls); i += 1) {
		static append(replb, (toutf8(repls[i].0), toutf8(repls[i].1)));
	};
	let b = toutf8(s);
	let res: []u8 = [];
	let i = 0z;
	let prev = 0z; // end of previous match, so we can append in chunks
	for (i < len(b)) :step {
		for (let j = 0z; j < len(replb); j += 1) {
			if (bytes::hasprefix(b[i..], replb[j].0)) {
				append(res, b[prev..i]...);
				append(res, replb[j].1...);
				i += len(replb[j].0);
				prev = i;
				continue :step;
			};
		};
		i += 1;
	};
	append(res, b[prev..i]...);
	return fromutf8(res)!;
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
		"baabaaba");
	assert(multireplace("hello there", ("e", "a"), ("a", "x"), ("ell", "eww")) == "hallo thara");
	assert(multireplace("hello there", ("ell", "eww"), ("e", "a")) == "hewwo thara");
};
