// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use math::random;
use sort::cmp;
use types;

@test fn lbisect() void = {
	const nums = [1, 3, 4, 4, 5, 7, 9, 11, 11, 11];
	for (let i = 0z; i < len(nums); i += 1) {
		if (i != 0 && nums[i - 1] == nums[i]) continue;
		const key = nums[i];
		assert(lbisect(nums, size(int), &key, &cmp::ints) == i);
	};
	const n = 0;
	assert(lbisect(nums, size(int), &n, &cmp::ints) == 0);
	const n = 6;
	assert(lbisect(nums, size(int), &n, &cmp::ints) == 5);
	const n = 8;
	assert(lbisect(nums, size(int), &n, &cmp::ints) == 6);
	const n = 12;
	assert(lbisect(nums, size(int), &n, &cmp::ints) == len(nums));
};

@test fn rbisect() void = {
	const nums = [1, 3, 4, 4, 5, 7, 9, 11, 11, 11];
	for (let i = 0z; i < len(nums); i += 1) {
		if (i != len(nums) - 1 && nums[i + 1] == nums[i]) continue;
		const key = nums[i];
		assert(rbisect(nums, size(int), &key, &cmp::ints) == i + 1);
	};
	const n = 0;
	assert(rbisect(nums, size(int), &n, &cmp::ints) == 0);
	const n = 6;
	assert(rbisect(nums, size(int), &n, &cmp::ints) == 5);
	const n = 8;
	assert(rbisect(nums, size(int), &n, &cmp::ints) == 6);
	const n = 12;
	assert(rbisect(nums, size(int), &n, &cmp::ints) == len(nums));
};

@test fn search() void = {
	const nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
	for (let i = 0z; i < len(nums); i += 1) {
		const key = nums[i];
		const p = search(nums, size(int), &key, &cmp::ints) as size;
		assert(p == i);
	};
	const key = 1337;
	assert(search(nums, size(int), &key, &cmp::ints) is void);
};

@test fn sort() void = {
	let nums = [
		1, 6, 10, 7, 8, 10, 10, 3, 7, 5, 5, 8, 1, 1, 1, 9, 2, 3, 1, 4,
		2, 1, 5, 3, 2, 5, 10, 1, 7, 6, 8, 10, 6, 5, 7, 4, 3, 9, 9, 4, 7,
		10, 3, 4, 4, 8, 5, 6, 2, 1, 6, 2, 2, 2, 10, 8, 3, 4, 5, 6, 6, 2,
		5, 2, 3, 7, 10, 7, 7, 5, 5, 2, 3, 4, 5, 3, 6, 2, 3, 6, 8, 8, 9,
		7, 10, 4, 10, 3, 2, 7, 10, 8, 8, 2, 2, 5, 3, 7, 4, 1,
	];
	sort(nums, size(int), &cmp::ints);
	for (let i = 1z; i < len(nums); i += 1) {
		assert(nums[i] >= nums[i - 1]);
	};
};

@test fn big_equal() void = {
	let nums = alloc([42...], 1000000);
	defer free(nums);
	sort(nums, size(int), &cmp::ints);
	for (let i = 0z; i < len(nums); i += 1) {
		assert(nums[i] == 42);
	};
};

@test fn big_random() void = {
	let nums = alloc([0...], 100000);
	defer free(nums);

	let rand = random::init(0x424242);
	for (let i = 0z; i < len(nums); i += 1) {
		nums[i] = random::next(&rand): int;
	};

	sort(nums, size(int), &cmp::ints);
	for (let i = 1z; i < len(nums); i += 1) {
		assert(nums[i] >= nums[i - 1]);
	};
};

@test fn sorted() void = {
	let nums = [1, 3, 2];

	assert(!sorted(nums, size(int), &cmp::ints));

	sort(nums, size(int), &cmp::ints);
	assert(sorted(nums, size(int), &cmp::ints));
	assert(sorted(nums[..0], size(int), &cmp::ints));
};

@test fn cmp::ints() void = {
	assert(cmp::ints(&5, &0) == 1);
	assert(cmp::ints(&0, &5) == -1);
	assert(cmp::ints(&0, &0) == 0);
	assert(cmp::ints(&0, &types::INT_MIN) == 1);
	assert(cmp::ints(&types::INT_MIN, &0) == -1);
};
