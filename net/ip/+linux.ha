// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use endian;
use rt;

export fn to_native(a: addr, port: u16) rt::sockaddr = {
	match (a) {
	case let v4: addr4 =>
		return rt::sockaddr {
			in = rt::sockaddr_in {
				sin_family = rt::AF_INET,
				sin_port = endian::htonu16(port),
				sin_addr = rt::in_addr { s_addr = *(&v4[0]: *opaque: *u32) },
				...
			},
			...
		};
	case let v6: addr6 =>
		return rt::sockaddr {
			in6 = rt::sockaddr_in6 {
				sin6_family = rt::AF_INET6,
				sin6_port = endian::htonu16(port),
				sin6_addr = rt::in6_addr { s6_addr = v6 },
				...
			},
			...
		};
	};
};

export fn from_native(a: rt::sockaddr) (addr, u16)  = {
	let family = a.in.sin_family;
	switch (family) {
	case rt::AF_INET =>
		let addr = a.in.sin_addr.s_addr;
		return (
			[addr: u8, (addr >> 8): u8, (addr >> 16): u8,
				(addr >> 24):  u8]: addr4,
			endian::ntohu16(a.in.sin_port)
		);
	case rt::AF_INET6 =>
		return (
			a.in6.sin6_addr.s6_addr: addr6,
			endian::ntohu16(a.in6.sin6_port)
		);
	case =>
		abort("Wrong address family!");
	};
};
