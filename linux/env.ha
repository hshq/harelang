// License: MPL-2.0
// (c) 2021 Mykyta Holubakha <hilobakho@gmail.com>
use format::elf;

// System V auxillary vector for the current process
export let auxv: *[*]elf::auxv64 = null: *[*]elf::auxv64;
