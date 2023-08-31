// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use rt;

// Exit the program with the provided status code.
export fn exit(status: int) never = {
	rt::fini();
	rt::exit(status);
};
