// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

@init fn init() void = {
	for (let i = 0z; i < len(arches); i += 1) {
		if (arches[i].name == "aarch64") {
            arches[i].qbe_name = "arm64_apple";
		} else if (arches[i].name == "x86_64") {
            arches[i].qbe_name = "amd64_apple";
		};
	};
};
