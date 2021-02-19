fn ncmp(a: const *void, b: const *void) int = {
	let a = a: const *int, b = b: const *int;
	return *a - *b;
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
