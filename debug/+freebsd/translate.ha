// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Tries to translate a pointer into an ELF address of the currently running
// binary.
export fn translate(ptr: uintptr) (uintptr | void) = {
	// TODO FreeBSD (will break when enabling PIE code)
	return ptr;
};
