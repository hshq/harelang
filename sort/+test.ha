// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use types;

@test fn lbisect() void = {
	const nums = [1, 3, 4, 4, 5, 7, 9, 11, 11, 11];
	for (let i = 0z; i < len(nums); i += 1) {
		if (i != 0 && nums[i - 1] == nums[i]) continue;
		const key = nums[i];
		assert(lbisect(nums, size(int), &key, &icmp) == i);
	};
	const n = 0;
	assert(lbisect(nums, size(int), &n, &icmp) == 0);
	const n = 6;
	assert(lbisect(nums, size(int), &n, &icmp) == 5);
	const n = 8;
	assert(lbisect(nums, size(int), &n, &icmp) == 6);
	const n = 12;
	assert(lbisect(nums, size(int), &n, &icmp) == len(nums));
};

@test fn rbisect() void = {
	const nums = [1, 3, 4, 4, 5, 7, 9, 11, 11, 11];
	for (let i = 0z; i < len(nums); i += 1) {
		if (i != len(nums) - 1 && nums[i + 1] == nums[i]) continue;
		const key = nums[i];
		assert(rbisect(nums, size(int), &key, &icmp) == i + 1);
	};
	const n = 0;
	assert(rbisect(nums, size(int), &n, &icmp) == 0);
	const n = 6;
	assert(rbisect(nums, size(int), &n, &icmp) == 5);
	const n = 8;
	assert(rbisect(nums, size(int), &n, &icmp) == 6);
	const n = 12;
	assert(rbisect(nums, size(int), &n, &icmp) == len(nums));
};

@test fn search() void = {
	const nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
	for (let i = 0z; i < len(nums); i += 1) {
		const key = nums[i];
		const p = search(nums, size(int), &key, &icmp) as size;
		assert(p == i);
	};
	const key = 1337;
	assert(search(nums, size(int), &key, &icmp) is void);
};

@test fn sort() void = {
	let nums = [
		1, 6, 10, 7, 8, 10, 10, 3, 7, 5, 5, 8, 1, 1, 1, 9, 2, 3, 1, 4,
		2, 1, 5, 3, 2, 5, 10, 1, 7, 6, 8, 10, 6, 5, 7, 4, 3, 9, 9, 4, 7,
		10, 3, 4, 4, 8, 5, 6, 2, 1, 6, 2, 2, 2, 10, 8, 3, 4, 5, 6, 6, 2,
		5, 2, 3, 7, 10, 7, 7, 5, 5, 2, 3, 4, 5, 3, 6, 2, 3, 6, 8, 8, 9,
		7, 10, 4, 10, 3, 2, 7, 10, 8, 8, 2, 2, 5, 3, 7, 4, 1,
	];
	sort(nums, size(int), &icmp);
	for (let i = 1z; i < len(nums); i += 1) {
		assert(nums[i] >= nums[i - 1]);
	};

};

@test fn sorted() void = {
	let nums = [1, 3, 2];

	assert(!sorted(nums, size(int), &icmp));

	sort(nums, size(int), &icmp);
	assert(sorted(nums, size(int), &icmp));
	assert(sorted(nums[..0], size(int), &icmp));
};

@test fn icmp() void = {
	assert(icmp(&5, &0) == 1);
	assert(icmp(&0, &5) == -1);
	assert(icmp(&0, &0) == 0);
	assert(icmp(&0, &types::INT_MIN) == 1);
	assert(icmp(&types::INT_MIN, &0) == -1);
};
