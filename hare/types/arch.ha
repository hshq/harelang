// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// Configuration for a specific architecture.
export type arch = struct {
	_int: size,
	_pointer: size,
	_size: size,
};

// [[arch]] configuration for x86_64.
export const x86_64: arch = arch {
	_int = 4,
	_pointer = 8,
	_size = 8,
};

// [[arch]] configuration for aarch64.
export const aarch64: arch = arch {
	_int = 4,
	_pointer = 8,
	_size = 8,
};
