fn ncmp(a: const *void, b: const *void) int = {
	let _a = a: const *int, _b = b: const *int;
	return *_a - *_b;
};

@test fn search() void = {
	const nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
	for (let i = 0z; i < len(nums); i += 1) {
		const key = nums[i];
		match (search(nums[..], size(int), &key, &ncmp): nullable *int) {
			null => abort(),
			p: *int => assert(p == &nums[i] && *p == nums[i]),
		};
	};
	const key = 1337;
	assert(search(nums[..], size(int), &key, &ncmp) == null);
};
