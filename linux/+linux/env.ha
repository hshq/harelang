// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use format::elf;

// System V auxillary vector for the current process
export let auxv: *[*]elf::auxv64 = null: *[*]elf::auxv64;
