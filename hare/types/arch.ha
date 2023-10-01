// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Configuration for a specific architecture.
export type arch = struct {
	_int: size,
	_pointer: size,
	_size: size,
	valist_size: size,
	valist_align: size,
};

// [[arch]] configuration for x86_64.
export const x86_64: arch = arch {
	_int = 4,
	_pointer = 8,
	_size = 8,
	valist_size = 24,
	valist_align = 8,
};

// [[arch]] configuration for aarch64.
export const aarch64: arch = arch {
	_int = 4,
	_pointer = 8,
	_size = 8,
	valist_size = 32,
	valist_align = 8,
};

// [[arch]] configuration for riscv64.
export const riscv64: arch = arch {
	_int = 4,
	_pointer = 8,
	_size = 8,
	valist_size = 8,
	valist_align = 8,
};
