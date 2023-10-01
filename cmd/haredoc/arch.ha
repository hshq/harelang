// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use hare::module;
use os;
use strings;

fn set_arch_tags(tags: *[]str, a: str) void = {
	merge_tags(tags, "-aarch64-riscv64-x86_64")!;
	append(tags, strings::dup(a));
};
