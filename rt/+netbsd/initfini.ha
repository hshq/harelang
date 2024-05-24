// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Run all global initialization functions.
export fn init() void = {
	const ninit = (&init_end: uintptr - &init_start: uintptr): size
		/ size(*fn() void);
	for (let i = 0z; i < ninit; i += 1) {
		init_start[i]();
	};
};

// Run all global finalization functions.
export fn fini() void = {
	const nfini = (&fini_end: uintptr - &fini_start: uintptr): size
		/ size(*fn() void);
	for (let i = nfini; i > 0; i -= 1) {
		fini_start[i - 1]();
	};
};
