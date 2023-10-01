// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type sa_family_t = u8;
export type socklen_t = u32;

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
export def SCM_CREDENTIALS: int = 0x02;

export type msghdr = struct {
	msg_name: nullable *opaque,
	msg_namelen: socklen_t,

	msg_iov: nullable *[*]iovec,
	msg_iovlen: int,

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

// <sys/socket.h>: Address families.
export def AF_UNSPEC         : sa_family_t = 0;
export def AF_UNIX           : sa_family_t = 1;
export def AF_LOCAL          : sa_family_t = AF_UNIX;
export def AF_INET           : sa_family_t = 2;
export def AF_IMPLINK        : sa_family_t = 3;
export def AF_PUP            : sa_family_t = 4;
export def AF_CHAOS          : sa_family_t = 5;
export def AF_NS             : sa_family_t = 6;
export def AF_ISO            : sa_family_t = 7;
export def AF_OSI            : sa_family_t = AF_ISO;
export def AF_ECMA           : sa_family_t = 8;
export def AF_DATAKIT        : sa_family_t = 9;
export def AF_CCITT          : sa_family_t = 10;
export def AF_SNA            : sa_family_t = 11;
export def AF_DECnet         : sa_family_t = 12;
export def AF_DLI            : sa_family_t = 13;
export def AF_LAT            : sa_family_t = 14;
export def AF_HYLINK         : sa_family_t = 15;
export def AF_APPLETALK      : sa_family_t = 16;
export def AF_ROUTE          : sa_family_t = 17;
export def AF_LINK           : sa_family_t = 18;
export def pseudo_AF_XTP     : sa_family_t = 19;
export def AF_COIP           : sa_family_t = 20;
export def AF_CNT            : sa_family_t = 21;
export def pseudo_AF_RTIP    : sa_family_t = 22;
export def AF_IPX            : sa_family_t = 23;
export def AF_SIP            : sa_family_t = 24;
export def pseudo_AF_PIP     : sa_family_t = 25;
export def AF_NDRV           : sa_family_t = 27;
export def AF_ISDN           : sa_family_t = 28;
export def AF_E164           : sa_family_t = AF_ISDN;
export def pseudo_AF_KEY     : sa_family_t = 29;
export def AF_INET6          : sa_family_t = 30;
export def AF_NATM           : sa_family_t = 31;
export def AF_SYSTEM         : sa_family_t = 32;
export def AF_NETBIOS        : sa_family_t = 33;
export def AF_PPP            : sa_family_t = 34;
export def AF_SCLUSTER       : sa_family_t = 34;
export def pseudo_AF_HDRCMPLT: sa_family_t = 35;
export def AF_RESERVED_36    : sa_family_t = 36;
export def AF_IEEE80211      : sa_family_t = 37;
export def AF_UTUN           : sa_family_t = 38;
export def AF_VSOCK          : sa_family_t = 40;
export def AF_MAX            : sa_family_t = 41;

// Types
export def SOCK_STREAM   : int = 1;
export def SOCK_DGRAM    : int = 2;
export def SOCK_RAW      : int = 3;
export def SOCK_RDM      : int = 4;
export def SOCK_SEQPACKET: int = 5;
export def SOCK_CLOEXEC  : int = 0x10000000;
export def SOCK_NONBLOCK : int = 0x20000000;

// <netinet/in.h>: Protocols (RFC 1700)
export def IPPROTO_IP       : int = 0;
export def IPPROTO_HOPOPTS  : int = 0;
export def IPPROTO_ICMP     : int = 1;
export def IPPROTO_IGMP     : int = 2;
export def IPPROTO_GGP      : int = 3;
export def IPPROTO_IPV4     : int = 4;
export def IPPROTO_IPIP     : int = IPPROTO_IPV4;
export def IPPROTO_TCP      : int = 6;
export def IPPROTO_ST       : int = 7;
export def IPPROTO_EGP      : int = 8;
export def IPPROTO_PIGP     : int = 9;
export def IPPROTO_RCCMON   : int = 10;
export def IPPROTO_NVPII    : int = 11;
export def IPPROTO_PUP      : int = 12;
export def IPPROTO_ARGUS    : int = 13;
export def IPPROTO_EMCON    : int = 14;
export def IPPROTO_XNET     : int = 15;
export def IPPROTO_CHAOS    : int = 16;
export def IPPROTO_UDP      : int = 17;
export def IPPROTO_MUX      : int = 18;
export def IPPROTO_MEAS     : int = 19;
export def IPPROTO_HMP      : int = 20;
export def IPPROTO_PRM      : int = 21;
export def IPPROTO_IDP      : int = 22;
export def IPPROTO_TRUNK1   : int = 23;
export def IPPROTO_TRUNK2   : int = 24;
export def IPPROTO_LEAF1    : int = 25;
export def IPPROTO_LEAF2    : int = 26;
export def IPPROTO_RDP      : int = 27;
export def IPPROTO_IRTP     : int = 28;
export def IPPROTO_TP       : int = 29;
export def IPPROTO_BLT      : int = 30;
export def IPPROTO_NSP      : int = 31;
export def IPPROTO_INP      : int = 32;
export def IPPROTO_SEP      : int = 33;
export def IPPROTO_3PC      : int = 34;
export def IPPROTO_IDPR     : int = 35;
export def IPPROTO_XTP      : int = 36;
export def IPPROTO_DDP      : int = 37;
export def IPPROTO_CMTP     : int = 38;
export def IPPROTO_TPXX     : int = 39;
export def IPPROTO_IL       : int = 40;
export def IPPROTO_IPV6     : int = 41;
export def IPPROTO_SDRP     : int = 42;
export def IPPROTO_ROUTING  : int = 43;
export def IPPROTO_FRAGMENT : int = 44;
export def IPPROTO_IDRP     : int = 45;
export def IPPROTO_RSVP     : int = 46;
export def IPPROTO_GRE      : int = 47;
export def IPPROTO_MHRP     : int = 48;
export def IPPROTO_BHA      : int = 49;
export def IPPROTO_ESP      : int = 50;
export def IPPROTO_AH       : int = 51;
export def IPPROTO_INLSP    : int = 52;
export def IPPROTO_SWIPE    : int = 53;
export def IPPROTO_NHRP     : int = 54;
export def IPPROTO_ICMPV6   : int = 58;
export def IPPROTO_NONE     : int = 59;
export def IPPROTO_DSTOPTS  : int = 60;
export def IPPROTO_AHIP     : int = 61;
export def IPPROTO_CFTP     : int = 62;
export def IPPROTO_HELLO    : int = 63;
export def IPPROTO_SATEXPAK : int = 64;
export def IPPROTO_KRYPTOLAN: int = 65;
export def IPPROTO_RVD      : int = 66;
export def IPPROTO_IPPC     : int = 67;
export def IPPROTO_ADFS     : int = 68;
export def IPPROTO_SATMON   : int = 69;
export def IPPROTO_VISA     : int = 70;
export def IPPROTO_IPCV     : int = 71;
export def IPPROTO_CPNX     : int = 72;
export def IPPROTO_CPHB     : int = 73;
export def IPPROTO_WSN      : int = 74;
export def IPPROTO_PVP      : int = 75;
export def IPPROTO_BRSATMON : int = 76;
export def IPPROTO_ND       : int = 77;
export def IPPROTO_WBMON    : int = 78;
export def IPPROTO_WBEXPAK  : int = 79;
export def IPPROTO_EON      : int = 80;
export def IPPROTO_VMTP     : int = 81;
export def IPPROTO_SVMTP    : int = 82;
export def IPPROTO_VINES    : int = 83;
export def IPPROTO_TTP      : int = 84;
export def IPPROTO_IGP      : int = 85;
export def IPPROTO_DGP      : int = 86;
export def IPPROTO_TCF      : int = 87;
export def IPPROTO_IGRP     : int = 88;
export def IPPROTO_OSPFIGP  : int = 89;
export def IPPROTO_SRPC     : int = 90;
export def IPPROTO_LARP     : int = 91;
export def IPPROTO_MTP      : int = 92;
export def IPPROTO_AX25     : int = 93;
export def IPPROTO_IPEIP    : int = 94;
export def IPPROTO_MICP     : int = 95;
export def IPPROTO_SCCSP    : int = 96;
export def IPPROTO_ETHERIP  : int = 97;
export def IPPROTO_ENCAP    : int = 98;
export def IPPROTO_APES     : int = 99;
export def IPPROTO_GMTP     : int = 100;
export def IPPROTO_PIM      : int = 103;
export def IPPROTO_IPCOMP   : int = 108;
export def IPPROTO_PGM      : int = 113;
export def IPPROTO_SCTP     : int = 132;
export def IPPROTO_DIVERT   : int = 254;
export def IPPROTO_RAW      : int = 255;
export def IPPROTO_MAX      : int = 256;
export def IPPROTO_DONE     : int = 257;

// <sys/socket.h>
export def MSG_OOB         : int = 0x00000001;
export def MSG_PEEK        : int = 0x00000002;
export def MSG_DONTROUTE   : int = 0x00000004;
export def MSG_EOR         : int = 0x00000008;
export def MSG_TRUNC       : int = 0x00000010;
export def MSG_CTRUNC      : int = 0x00000020;
export def MSG_WAITALL     : int = 0x00000040;
export def MSG_DONTWAIT    : int = 0x00000080;
export def MSG_EOF         : int = 0x00000100;
export def MSG_WAITSTREAM  : int = 0x00000200;
export def MSG_FLUSH       : int = 0x00000400;
export def MSG_HOLD        : int = 0x00000800;
export def MSG_SEND        : int = 0x00001000;
export def MSG_HAVEMORE    : int = 0x00002000;
export def MSG_RCVMORE     : int = 0x00004000;
// export def MSG_COMPAT      : int = 0x00008000;
export def MSG_NEEDSA      : int = 0x00010000;
export def MSG_NOSIGNAL    : int = 0x00080000;
// export def MSG_CMSG_CLOEXEC: int = 0x00040000;
// export def MSG_WAITFORONE  : int = 0x00080000;

// <sys/socket.h>: Option flags per-socket.
export def SO_DEBUG              : int = 0x0001;
export def SO_ACCEPTCONN         : int = 0x0002;
export def SO_REUSEADDR          : int = 0x0004;
export def SO_KEEPALIVE          : int = 0x0008;
export def SO_DONTROUTE          : int = 0x0010;
export def SO_BROADCAST          : int = 0x0020;
export def SO_USELOOPBACK        : int = 0x0040;
export def SO_LINGER             : int = 0x0080;
export def SO_OOBINLINE          : int = 0x0100;
export def SO_REUSEPORT          : int = 0x0200;
export def SO_TIMESTAMP          : int = 0x0400;
export def SO_TIMESTAMP_MONOTONIC: int = 0x0800;
export def SO_DONTTRUNC          : int = 0x2000;
export def SO_WANTMORE           : int = 0x4000;
export def SO_WANTOOBFLAG        : int = 0x8000;
// Additional options, not kept in so_options.
// export def SO_NOSIGPIPE: int = 0x00000800;
export def SO_SNDBUF              : int = 0x1001;
export def SO_RCVBUF              : int = 0x1002;
export def SO_SNDLOWAT            : int = 0x1003;
export def SO_RCVLOWAT            : int = 0x1004;
export def SO_SNDTIMEO            : int = 0x1005;
export def SO_RCVTIMEO            : int = 0x1006;
export def SO_ERROR               : int = 0x1007;
export def SO_TYPE                : int = 0x1008;
export def SO_LABEL               : int = 0x1010;
export def SO_PEERLABEL           : int = 0x1011;
export def SO_NREAD               : int = 0x1020;
export def SO_NKE                 : int = 0x1021;
export def SO_NOSIGPIPE           : int = 0x1022;
export def SO_NOADDRERR           : int = 0x1023;
export def SO_NWRITE              : int = 0x1024;
export def SO_REUSESHAREUID       : int = 0x1025;
export def SO_NOTIFYCONFLICT      : int = 0x1026;
export def SO_UPCALLCLOSEWAIT     : int = 0x1027;
export def SO_LINGER_SEC          : int = 0x1080;
export def SO_RANDOMPORT          : int = 0x1082;
export def SO_NP_EXTENSIONS       : int = 0x1083;
export def SO_NUMRCVPKT           : int = 0x1112;
export def SO_NETSVC_MARKING_LEVEL: int = 0x1119;

export def SOL_SOCKET: int = 0xffff;
