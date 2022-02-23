// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>

fn ncmp(a: const *void, b: const *void) int = {
	let a = a: const *int, b = b: const *int;
	return *a - *b;
};

@test fn search() void = {
	const nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
	for (let i = 0z; i < len(nums); i += 1) {
		const key = nums[i];
		match (search(nums[..], size(int), &key, &ncmp): nullable *int) {
		case null =>
			abort();
		case let p: *int =>
			assert(p == &nums[i] && *p == nums[i]);
		};
	};
	const key = 1337;
	assert(search(nums[..], size(int), &key, &ncmp) == null);
};

@test fn sort() void = {
	let nums = [
		1, 6, 10, 7, 8, 10, 10, 3, 7, 5, 5, 8, 1, 1, 1, 9, 2, 3, 1, 4,
		2, 1, 5, 3, 2, 5, 10, 1, 7, 6, 8, 10, 6, 5, 7, 4, 3, 9, 9, 4, 7,
		10, 3, 4, 4, 8, 5, 6, 2, 1, 6, 2, 2, 2, 10, 8, 3, 4, 5, 6, 6, 2,
		5, 2, 3, 7, 10, 7, 7, 5, 5, 2, 3, 4, 5, 3, 6, 2, 3, 6, 8, 8, 9,
		7, 10, 4, 10, 3, 2, 7, 10, 8, 8, 2, 2, 5, 3, 7, 4, 1,
	];
	sort(nums[..], size(int), &ncmp);
	for (let i = 1z; i < len(nums); i += 1) {
		assert(nums[i] >= nums[i - 1]);
	};
};
