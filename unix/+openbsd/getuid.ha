// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Returns the current process user ID.
export fn getuid() uint = rt::getuid(): uint;

// Returns the current process effective user ID.
export fn geteuid() uint = rt::geteuid(): uint;

// Returns the current process group ID.
export fn getgid() uint = rt::getgid(): uint;

// Returns the current process effective group ID.
export fn getegid() uint = rt::getegid(): uint;