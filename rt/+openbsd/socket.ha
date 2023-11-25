// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type socklen_t = u32;
export type sa_family_t = u8;

export type in_addr = struct {
	s_addr: u32
};

export type sockaddr_in = struct {
	sin_len: u8,
	sin_family: sa_family_t,
	sin_port: u16,
	sin_addr: in_addr,
	__pad: [8]u8,
};

export type in6_addr = struct {
	union {
		s6_addr: [16]u8,
		s6_addr16: [8]u16,
		s6_addr32: [4]u32,
	}
};

export type sockaddr_in6 = struct {
	sin6_len: u8,
	sin6_family: sa_family_t,
	sin6_port: u16,
	sin6_flowinfo: u32,
	sin6_addr: in6_addr,
	sin6_scope_id: u32,
};

export def UNIX_PATH_MAX: size = 104;

export type sockaddr_un = struct {
	sun_len: u8,
	sun_family: sa_family_t,
	sun_path: [UNIX_PATH_MAX]u8,
};

export type sockaddr = struct {
	union {
		in: sockaddr_in,
		in6: sockaddr_in6,
		un: sockaddr_un,
	},
};

export def SCM_RIGHTS: int = 0x01;
export def SCM_TIMESTAMP: int = 0x04;

export type msghdr = struct {
	msg_name: nullable *opaque,
	msg_namelen: socklen_t,
	msg_iov: nullable *[*]iovec,
	msg_iovlen: uint,
	msg_control: nullable *opaque,
	msg_controllen: socklen_t,
	msg_flags: int
};

export type cmsghdr = struct {
	cmsg_len: socklen_t,
	cmsg_level: int,
	cmsg_type: int,
};

export type cmsg = struct {
	hdr: cmsghdr,
	cmsg_data: [*]u8,
};

export def SOCK_STREAM: int = 1;
export def SOCK_DGRAM: int = 2;
export def SOCK_RAW: int = 3;
export def SOCK_RDM: int = 4;
export def SOCK_SEQPACKET: int = 5;

export def SOCK_CLOEXEC: int = 0x8000;
export def SOCK_NONBLOCK: int = 0x4000;

export def SOL_SOCKET: int = 0xffff;

export def AF_UNSPEC: sa_family_t = 0;
export def AF_UNIX: sa_family_t = 1;
export def AF_LOCAL: sa_family_t = AF_UNIX;
export def AF_INET: sa_family_t = 2;
export def AF_IMPLINK: sa_family_t = 3;
export def AF_PUP: sa_family_t = 4;
export def AF_CHAOS: sa_family_t = 5;
export def AF_NS: sa_family_t = 6;
export def AF_ISO: sa_family_t = 7;
export def AF_OSI: sa_family_t = AF_ISO;
export def AF_ECMA: sa_family_t = 8;
export def AF_DATAKIT: sa_family_t = 9;
export def AF_CCITT: sa_family_t = 10;
export def AF_SNA: sa_family_t = 11;
export def AF_DECnet: sa_family_t = 12;
export def AF_DLI: sa_family_t = 13;
export def AF_LAT: sa_family_t = 14;
export def AF_HYLINK: sa_family_t = 15;
export def AF_APPLETALK: sa_family_t = 16;
export def AF_ROUTE: sa_family_t = 17;
export def AF_LINK: sa_family_t = 18;
export def pseudo_AF_XTP: sa_family_t = 19;
export def AF_COIP: sa_family_t = 20;
export def AF_CNT: sa_family_t = 21;
export def pseudo_AF_RTIP: sa_family_t = 22;
export def AF_IPX: sa_family_t = 23;
export def AF_INET6: sa_family_t = 24;
export def pseudo_AF_PIP: sa_family_t = 25;
export def AF_ISDN: sa_family_t = 26;
export def AF_E164: sa_family_t = AF_ISDN;
export def AF_NATM: sa_family_t = 27;
export def AF_ENCAP: sa_family_t = 28;
export def AF_SIP: sa_family_t = 29;
export def AF_KEY: sa_family_t = 30;
export def pseudo_AF_HDRCMPLT: sa_family_t = 31;

export def SO_DEBUG: int = 0x0001;
export def SO_ACCEPTCONN: int = 0x0002;
export def SO_REUSEADDR: int = 0x0004;
export def SO_KEEPALIVE: int = 0x0008;
export def SO_DONTROUTE: int = 0x0010;
export def SO_BROADCAST: int = 0x0020;
export def SO_USELOOPBACK: int = 0x0040;
export def SO_LINGER: int = 0x0080;
export def SO_OOBINLINE: int = 0x0100;
export def SO_REUSEPORT: int = 0x0200;
export def SO_TIMESTAMP: int = 0x0800;
export def SO_BINDANY: int = 0x1000;
export def SO_ZEROIZE: int = 0x2000;

export def SO_SNDBUF: int = 0x1001;
export def SO_RCVBUF: int = 0x1002;
export def SO_SNDLOWAT: int = 0x1003;
export def SO_RCVLOWAT: int = 0x1004;
export def SO_SNDTIMEO: int = 0x1005;
export def SO_RCVTIMEO: int = 0x1006;
export def SO_ERROR: int = 0x1007;
export def SO_TYPE: int = 0x1008;
export def SO_NETPROC: int = 0x1020;
export def SO_RTABLE: int = 0x1021;
export def SO_PEERCRED: int = 0x1022;
export def SO_SPLICE: int = 0x1023;
export def SO_DOMAIN: int = 0x1024;
export def SO_PROTOCOL: int = 0x1025;
