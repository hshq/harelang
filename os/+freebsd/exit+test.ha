// License: MPL-2.0
// (c) 2023 Sebastian <sebastian@sebsite.pw>

// Exit the program with the provided status code.
export @noreturn fn exit(status: int) void = {
	abort("os::exit disabled in +test");
};
