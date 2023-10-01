// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use math;

// test round-trip accuracy of ftos followed by stof.
@test fn ftostof() void = {
	const tcs: []f64 = [
		1.0,
		0.0,
		0.1,
		-0.0,
		1f64 / 3f64,
		4f64 / 3f64,

		1f64 / 0f64,
		-1f64 / 0f64,

		0f64 / 0f64,
	];
	for (let i = 0z; i < len(tcs); i += 1) {
		const res64 = stof64(f64tos(tcs[i]))!;
		const res32 = stof32(f32tos(tcs[i]: f32))!;
		// there can be multiple NaNs. only test isnan.
		if (math::isnan(tcs[i])) {
			assert(math::isnan(res64));
			assert(math::isnan(res32));
		} else {
			assert(tcs[i] == res64);
			assert(tcs[i]: f32 == res32);
		};
	};
};
