// License: MPL-2.0
// (c) 2023 Sebastian <sebastian@sebsite.pw>

// Exit the program with the provided status code.
export fn exit(status: int) never = {
	abort("os::exit disabled in +test");
};
