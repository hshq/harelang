// Replaces all instances of 'needle' with 'target' in 's'.
// The caller must free the return value.
export fn replace(s: str, needle: str, target: str) str = {
	let res = dup(s);

	let n_needle_runes = 0z;
	let needle_iter = iter(needle);
	for (!(next(&needle_iter) is void)) {
		n_needle_runes += 1;
	};

	for (true) {
		const match_idx = match(index(res, needle)) {
		case let s: size =>
			yield s;
		case void =>
			break;
		};
		let old_res = res;
		const bytes = toutf8(res);
		// TODO: Stop allocating so much, as it will become a perf issue
		// with many replacements.
		res = concat(sub(res, 0, match_idx),
			target,
			sub(res, match_idx + n_needle_runes, end));
		free(old_res);
	};
	return res;
};

@test fn replace() void = {
	assert(replace("Hello world!", "world", "there") == "Hello there!");
	assert(replace("I like dogs, dogs, birds, dogs", "dogs", "cats") ==
		"I like cats, cats, birds, cats");
	assert(replace("こんにちは", "にち", "ばん") == "こんばんは");
};
