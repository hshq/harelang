// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Returns a list of supplementary group IDs for the current process. The
// returned slice is statically allocated.
export fn getgroups() []uint = {
	static let gids: [rt::NGROUPS_MAX]uint = [0...];
	const n = rt::getgroups(gids)!;
	return gids[..n];
};

// Sets the list of supplementary group IDs which apply to the current process.
// This generally requires elevated permissions.
//
// If the system returns an error, this function will abort the program. Failing
// to handle errors from setgroups is a grave security issue in your program,
// and therefore we require this function to succeed. If you need to handle the
// error case gracefully, call the appropriate syscall wrapper in [[rt::]]
// yourself, and take extreme care to handle errors correctly.
export fn setgroups(gids: []uint) void = rt::setgroups(gids)!;
