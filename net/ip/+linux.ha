use rt;
use endian;

export fn to_native(a: addr, port: u16) rt::sockaddr = {
	return match (a) {
		v4: addr4 => rt::sockaddr { in = rt::sockaddr_in {
			sin_family = rt::AF_INET,
			sin_port = endian::htonu16(port),
			sin_addr = rt::in_addr { s_addr = *(&v4[0]: *void: *u32) },
		} },
		v6: addr6 => rt::sockaddr { in6 = rt::sockaddr_in6 {
			sin6_family = rt::AF_INET6,
			sin6_port = endian::htonu16(port),
			sin6_addr = rt::in6_addr { s6_addr = v6 },
		} },
	};
};
