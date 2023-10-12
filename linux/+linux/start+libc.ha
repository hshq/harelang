// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;
use rt;

@init fn init_linux() void = {
	let i = 0;
	for (rt::envp[i] != null) {
		i += 1;
	};
	auxv = &rt::envp[i + 1]: *[*]elf::auxv64;
};
