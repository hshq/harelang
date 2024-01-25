// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;
use types::c;

// Tries to translate a pointer into an ELF address of the currently running
// binary.
export fn translate(ptr: uintptr) (uintptr | void) = {
	let dl_info = rt::dl_info { ... };

	// In order to avoid translating symbols in shared libaries and
	// producing invalid results, use the current function (which should be
	// in the main binary) to get the base image address.
	//
	// Theoretically, it should be possible to get symbol names from shared
	// libaries. You would have to load the ELF shared libary at the path
	// [[dl_info.fname]] as an ELF image and resolve the symbol name
	// from there. Then you could do "s/&translate/ptr" below.
	const ret = rt::dladdr(&translate: *opaque, &dl_info);
	if (ret != 0) {
		return ptr - dl_info.fbase: uintptr;
	};
};
