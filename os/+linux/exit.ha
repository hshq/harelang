// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use rt;

// Values that may be passed to [[exit]] to indicate successful or unsuccessful
// termination, respectively.
export type status = enum {
	SUCCESS = 0,
	FAILURE = 1,
};

// Exit the program with the provided status code.
export @noreturn fn exit(status: int) void = {
	rt::fini();
	rt::exit(status);
};
