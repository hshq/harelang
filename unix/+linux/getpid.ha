// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Returns the current process ID.
export fn getpid() int = rt::getpid();
