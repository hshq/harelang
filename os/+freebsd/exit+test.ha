// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Exit the program with the provided status code.
export fn exit(status: int) never = {
	abort("os::exit disabled in +test");
};
