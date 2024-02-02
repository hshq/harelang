// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;
use types::c;

// Tries to translate a pointer into an ELF address of the currently running
// binary.
export fn translate(ptr: uintptr) (uintptr | void) = {
	// TODO Linux (will break when enabling PIE code)
	return ptr;
};
