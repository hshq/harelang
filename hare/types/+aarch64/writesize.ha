// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use hash;

fn writesize(h: *hash::hash, u: size) void = write64(h, u);
