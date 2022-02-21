// License: MPL-2.0
// (c) 2021 Mykyta Holubakha <hilobakho@gmail.com>
use format::elf;

// System V auxillary vector for the current process
export let auxv: *[*]format::elf::auxv64 = null: *[*]format::elf::auxv64;
