use rt;
use strings;

// Converts a UNIX socket address to a native sockaddr.
export fn to_native(addr: addr) (rt::sockaddr | invalid) = {
	// sun_path should be null-terminated and fit into rt::UNIX_PATH_MAX
	if (len(addr) > rt::UNIX_PATH_MAX - 1) {
		return invalid;
	};
	let ret = rt::sockaddr {
		un = rt::sockaddr_un {
			sun_family = rt::AF_UNIX,
			...
		}
	};
	rt::memcpy(&ret.un.sun_path,
		(&addr: *types::string).data, len(addr));
	ret.un.sun_path[len(addr)] = 0;
	return ret;
};

// Converts a native sockaddr to a UNIX socket address. The return value is
// borrowed from the input.
export fn from_native(a: rt::sockaddr) addr = {
	return switch (a.in.sin_family) {
		rt::AF_UNIX => strings::fromc(&a.un.sun_path[0]),
		* => abort("Wrong address family!"),
	};
};
