// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

export type sa_family_t = u16;
export type socklen_t = uint;

export type in_addr = struct {
	s_addr: u32
};

export type sockaddr_in = struct {
	sin_family: sa_family_t,
	sin_port: u16,
	sin_addr: in_addr,
	__pad: [16]u8,
};

export type in6_addr = struct {
	union {
		s6_addr: [16]u8,
		s6_addr16: [8]u16,
		s6_addr32: [4]u32,
	}
};

export type sockaddr_in6 = struct {
	sin6_family: sa_family_t,
	sin6_port: u16,
	sin6_flowinfo: u32,
	sin6_addr: in6_addr,
	sin6_scope_id: u32,
};

export def UNIX_PATH_MAX: size = 108;

export type sockaddr_un = struct {
	sun_family: sa_family_t,
	sun_path: [UNIX_PATH_MAX]u8,
};

export type sockaddr_nl = struct {
	nl_family: sa_family_t,
	nl_pad: u16,
	nl_pid: u32,
	nl_groups: u32,
};

export type sockaddr_ll = struct {
	sll_family: sa_family_t,
	sll_protocol: u16,
	sll_ifindex: int,
	sll_hatype: u16,
	sll_pkttype: u8,
	sll_halen: u8,
	sll_addr: [8]u8,
};

export type sockaddr = struct {
	union {
		in: sockaddr_in,
		in6: sockaddr_in6,
		un: sockaddr_un,
		nl: sockaddr_nl,
		ll: sockaddr_ll,
	},
};

export def SCM_RIGHTS: int = 0x01;
export def SCM_CREDENTIALS: int = 0x02;

export type msghdr = struct {
	msg_name: nullable *opaque,
	msg_namelen: u32,

	msg_iov: nullable *[*]iovec,
	msg_iovlen: size,

	msg_control: nullable *opaque,
	msg_controllen: size,

	msg_flags: int
};

export type cmsg = struct {
	hdr: cmsghdr,
	cmsg_data: [*]u8,
};

export type sock_filter = struct {
	__code: u16,
	__jt: u8,
	__jf: u8,
	__k: u32,
};

export type sock_fprog = struct {
	__len: u16,
	__filter: *[*]sock_filter,
};

// domain for socket(2)

// Unspecified
export def AF_UNSPEC: sa_family_t = 0;
// Unix domain sockets
export def AF_UNIX: sa_family_t = 1;
// POSIX name for AF_UNIX
export def AF_LOCAL: sa_family_t = 1;
// Internet IP Protocol
export def AF_INET: sa_family_t = 2;
// Amateur Radio AX.25
export def AF_AX25: sa_family_t = 3;
// Novell IPX
export def AF_IPX: sa_family_t = 4;
// AppleTalk DDP
export def AF_APPLETALK: sa_family_t = 5;
// Amateur Radio NET/ROM
export def AF_NETROM: sa_family_t = 6;
// Multiprotocol bridge
export def AF_BRIDGE: sa_family_t = 7;
// ATM PVCs
export def AF_ATMPVC: sa_family_t = 8;
// Reserved for X.25 project
export def AF_X25: sa_family_t = 9;
// IP version 6
export def AF_INET6: sa_family_t = 10;
// Amateur Radio X.25 PLP
export def AF_ROSE: sa_family_t = 11;
// Reserved for DECnet project
export def AF_DECnet: sa_family_t = 12;
// Reserved for 802.2LLC project
export def AF_NETBEUI: sa_family_t = 13;
// Security callback pseudo AF
export def AF_SECURITY: sa_family_t = 14;
// PF_KEY key management API
export def AF_KEY: sa_family_t = 15;
// Linux netlink API
export def AF_NETLINK: sa_family_t = 16;
// Alias to emulate 4.4BSD
export def AF_ROUTE: sa_family_t = AF_NETLINK;
// Packet family
export def AF_PACKET: sa_family_t = 17;
// Ash
export def AF_ASH: sa_family_t = 18;
// Acorn Econet
export def AF_ECONET: sa_family_t = 19;
// ATM SVCs
export def AF_ATMSVC: sa_family_t = 20;
// RDS sockets
export def AF_RDS: sa_family_t = 21;
// Linux SNA Project (nutters!)
export def AF_SNA: sa_family_t = 22;
// IRDA sockets
export def AF_IRDA: sa_family_t = 23;
// PPPoX sockets
export def AF_PPPOX: sa_family_t = 24;
// Wanpipe API Sockets
export def AF_WANPIPE: sa_family_t = 25;
// Linux LLC
export def AF_LLC: sa_family_t = 26;
// Native InfiniBand address
export def AF_IB: sa_family_t = 27;
// MPLS
export def AF_MPLS: sa_family_t = 28;
// Controller Area Network
export def AF_CAN: sa_family_t = 29;
// TIPC sockets
export def AF_TIPC: sa_family_t = 30;
// Bluetooth sockets
export def AF_BLUETOOTH: sa_family_t = 31;
// IUCV sockets
export def AF_IUCV: sa_family_t = 32;
// RxRPC sockets
export def AF_RXRPC: sa_family_t = 33;
// mISDN sockets
export def AF_ISDN: sa_family_t = 34;
// Phonet sockets
export def AF_PHONET: sa_family_t = 35;
// IEEE802154 sockets
export def AF_IEEE802154: sa_family_t = 36;
// CAIF sockets
export def AF_CAIF: sa_family_t = 37;
// Algorithm sockets
export def AF_ALG: sa_family_t = 38;
// NFC sockets
export def AF_NFC: sa_family_t = 39;
// vSockets
export def AF_VSOCK: sa_family_t = 40;
// Kernel Connection Multiplexor
export def AF_KCM: sa_family_t = 41;
// Qualcomm IPC Router
export def AF_QIPCRTR: sa_family_t = 42;
// smc sockets
export def AF_SMC: sa_family_t = 43;
// XDP sockets
export def AF_XDP: sa_family_t = 44;

// type for socket(2)
export def SOCK_STREAM: int = 1;
export def SOCK_DGRAM: int = 2;
export def SOCK_RAW: int = 3;
export def SOCK_RDM: int = 4;
export def SOCK_SEQPACKET: int = 5;
export def SOCK_DCCP: int = 6;
export def SOCK_PACKET: int = 10;
export def SOCK_NONBLOCK: int = 0o4000;
export def SOCK_CLOEXEC: int = 0o2000000;

// protocol for socket(2)
export def ETH_P_15: int = 0x88f7;
export def ETH_P_8021AD: int = 0x88a8;
export def ETH_P_8021AH: int = 0x88e7;
export def ETH_P_8021Q: int = 0x8100;
export def ETH_P_80221: int = 0x8917;
export def ETH_P_802_2: int = 0x4;
export def ETH_P_802_3: int = 0x1;
export def ETH_P_802_3_MIN: int = 0x600;
export def ETH_P_802_EX1: int = 0x88b5;
export def ETH_P_AARP: int = 0x80f3;
export def ETH_P_AF_IUCV: int = 0xfbfb;
export def ETH_P_ALL: int = 0x3;
export def ETH_P_AOE: int = 0x88a2;
export def ETH_P_ARCNET: int = 0x1a;
export def ETH_P_ARP: int = 0x806;
export def ETH_P_ATALK: int = 0x809b;
export def ETH_P_ATMFATE: int = 0x8884;
export def ETH_P_ATMMPOA: int = 0x884c;
export def ETH_P_AX25: int = 0x2;
export def ETH_P_BATMAN: int = 0x4305;
export def ETH_P_BPQ: int = 0x8ff;
export def ETH_P_CAIF: int = 0xf7;
export def ETH_P_CAN: int = 0xc;
export def ETH_P_CANFD: int = 0xd;
export def ETH_P_CANXL: int = 0xe;
export def ETH_P_CFM: int = 0x8902;
export def ETH_P_CONTROL: int = 0x16;
export def ETH_P_CUST: int = 0x6006;
export def ETH_P_DDCMP: int = 0x6;
export def ETH_P_DEC: int = 0x6000;
export def ETH_P_DIAG: int = 0x6005;
export def ETH_P_DNA_DL: int = 0x6001;
export def ETH_P_DNA_RC: int = 0x6002;
export def ETH_P_DNA_RT: int = 0x6003;
export def ETH_P_DSA: int = 0x1b;
export def ETH_P_DSA_8021Q: int = 0xdadb;
export def ETH_P_DSA_A5PSW: int = 0xe001;
export def ETH_P_ECONET: int = 0x18;
export def ETH_P_EDSA: int = 0xdada;
export def ETH_P_ERSPAN: int = 0x88be;
export def ETH_P_ERSPAN2: int = 0x22eb;
export def ETH_P_ETHERCAT: int = 0x88a4;
export def ETH_P_FCOE: int = 0x8906;
export def ETH_P_FIP: int = 0x8914;
export def ETH_P_HDLC: int = 0x19;
export def ETH_P_HSR: int = 0x892f;
export def ETH_P_IBOE: int = 0x8915;
export def ETH_P_IEEE802154: int = 0xf6;
export def ETH_P_IEEEPUP: int = 0xa00;
export def ETH_P_IEEEPUPAT: int = 0xa01;
export def ETH_P_IFE: int = 0xed3e;
export def ETH_P_IP: int = 0x800;
export def ETH_P_IPV6: int = 0x86dd;
export def ETH_P_IPX: int = 0x8137;
export def ETH_P_IRDA: int = 0x17;
export def ETH_P_LAT: int = 0x6004;
export def ETH_P_LINK_CTL: int = 0x886c;
export def ETH_P_LLDP: int = 0x88cc;
export def ETH_P_LOCALTALK: int = 0x9;
export def ETH_P_LOOP: int = 0x60;
export def ETH_P_LOOPBACK: int = 0x9000;
export def ETH_P_MACSEC: int = 0x88e5;
export def ETH_P_MAP: int = 0xf9;
export def ETH_P_MCTP: int = 0xfa;
export def ETH_P_MOBITEX: int = 0x15;
export def ETH_P_MPLS_MC: int = 0x8848;
export def ETH_P_MPLS_UC: int = 0x8847;
export def ETH_P_MRP: int = 0x88e3;
export def ETH_P_MVRP: int = 0x88f5;
export def ETH_P_NCSI: int = 0x88f8;
export def ETH_P_NSH: int = 0x894f;
export def ETH_P_PAE: int = 0x888e;
export def ETH_P_PAUSE: int = 0x8808;
export def ETH_P_PHONET: int = 0xf5;
export def ETH_P_PPPTALK: int = 0x10;
export def ETH_P_PPP_DISC: int = 0x8863;
export def ETH_P_PPP_MP: int = 0x8;
export def ETH_P_PPP_SES: int = 0x8864;
export def ETH_P_PREAUTH: int = 0x88c7;
export def ETH_P_PROFINET: int = 0x8892;
export def ETH_P_PRP: int = 0x88fb;
export def ETH_P_PUP: int = 0x200;
export def ETH_P_PUPAT: int = 0x201;
export def ETH_P_QINQ1: int = 0x9100;
export def ETH_P_QINQ2: int = 0x9200;
export def ETH_P_QINQ3: int = 0x9300;
export def ETH_P_RARP: int = 0x8035;
export def ETH_P_REALTEK: int = 0x8899;
export def ETH_P_SCA: int = 0x6007;
export def ETH_P_SLOW: int = 0x8809;
export def ETH_P_SNAP: int = 0x5;
export def ETH_P_TDLS: int = 0x890d;
export def ETH_P_TEB: int = 0x6558;
export def ETH_P_TIPC: int = 0x88ca;
export def ETH_P_TRAILER: int = 0x1c;
export def ETH_P_TR_802_2: int = 0x11;
export def ETH_P_TSN: int = 0x22f0;
export def ETH_P_WAN_PPP: int = 0x7;
export def ETH_P_WCCP: int = 0x883e;
export def ETH_P_X25: int = 0x805;
export def ETH_P_XDSA: int = 0xf8;

// Dummy protocol for TCP
export def IPPROTO_IP: int = 0;
// Internet Control Message Protocol
export def IPPROTO_ICMP: int = 1;
// Internet Group Management Protocol
export def IPPROTO_IGMP: int = 2;
// IPIP tunnels (older KA9Q tunnels use 94)
export def IPPROTO_IPIP: int = 4;
// Transmission Control Protocol
export def IPPROTO_TCP: int = 6;
// Exterior Gateway Protocol
export def IPPROTO_EGP: int = 8;
// PUP protocol
export def IPPROTO_PUP: int = 12;
// User Datagram Protocol
export def IPPROTO_UDP: int = 17;
// XNS IDP protocol
export def IPPROTO_IDP: int = 22;
// SO Transport Protocol Class 4
export def IPPROTO_TP: int = 29;
// Datagram Congestion Control Protocol
export def IPPROTO_DCCP: int = 33;
// IPv6-in-IPv4 tunnelling
export def IPPROTO_IPV6: int = 41;
// RSVP Protocol
export def IPPROTO_RSVP: int = 46;
// Cisco GRE tunnels (rfc 1701,1702)
export def IPPROTO_GRE: int = 47;
// Encapsulation Security Payload protocol
export def IPPROTO_ESP: int = 50;
// Authentication Header protocol
export def IPPROTO_AH: int = 51;
// ICMPv6
export def IPPROTO_ICMPV6: int = 58;
// Multicast Transport Protocol
export def IPPROTO_MTP: int = 92;
// IP option pseudo header for BEET
export def IPPROTO_BEETPH: int = 94;
// Encapsulation Header
export def IPPROTO_ENCAP: int = 98;
// Protocol Independent Multicast
export def IPPROTO_PIM: int = 103;
// Compression Header Protocol
export def IPPROTO_COMP: int = 108;
// Stream Control Transport Protocol
export def IPPROTO_SCTP: int = 132;
// UDP-Lite (RFC 3828)
export def IPPROTO_UDPLITE: int = 136;
// MPLS in IP (RFC 4023)
export def IPPROTO_MPLS: int = 137;
// Ethernet-within-IPv6 Encapsulation
export def IPPROTO_ETHERNET: int = 143;
// Raw IP packets
export def IPPROTO_RAW: int = 255;
// Multipath TCP connection
export def IPPROTO_MPTCP: int = 262;

// send/rcv flags
export def MSG_OOB: int = 1;
export def MSG_PEEK: int = 2;
export def MSG_DONTROUTE: int = 4;
export def MSG_TRYHARD: int = 4; // Synonym for MSG_DONTROUTE for DECnet
export def MSG_CTRUNC: int = 8;
export def MSG_PROBE: int = 0x10; // Do not send. Only probe path f.e. for MTU
export def MSG_TRUNC: int = 0x20;
export def MSG_DONTWAIT: int = 0x40; // Nonblocking io
export def MSG_EOR: int = 0x80; // End of record
export def MSG_WAITALL: int = 0x100; // Wait for a full request
export def MSG_FIN: int = 0x200;
export def MSG_SYN: int = 0x400;
export def MSG_CONFIRM: int = 0x800; // Confirm path validity
export def MSG_RST: int = 0x1000;
export def MSG_ERRQUEUE: int = 0x2000; // Fetch message from error queue
export def MSG_NOSIGNAL: int = 0x4000; // Do not generate SIGPIPE
export def MSG_MORE: int = 0x8000; // Sender will send more
export def MSG_WAITFORONE: int = 0x10000; // recvmmsg(): block until 1+ packets avail
export def MSG_SENDPAGE_NOPOLICY: int = 0x10000; // sendpage() internal : do no apply policy
export def MSG_SENDPAGE_NOTLAST: int = 0x20000; // sendpage() internal : not the last page
export def MSG_BATCH: int = 0x40000; // sendmmsg(): more messages coming
export def MSG_EOF: int = MSG_FIN;
export def MSG_NO_SHARED_FRAGS: int = 0x80000; // sendpage() internal : page frags are not shared
export def MSG_SENDPAGE_DECRYPTED: int = 0x100000; // sendpage() internal : page may carry * plain text and require encryption
export def MSG_ZEROCOPY: int = 0x4000000; // Use user data in kernel path
export def MSG_FASTOPEN: int = 0x20000000; // Send data in TCP SYN
export def MSG_CMSG_CLOEXEC: int = 0x40000000; // Set close_on_exec for file descriptor received through SCM_RIGHTS

// setsockopt levels
export def SOL_SOCKET: int = 1;

// setsockopt options
export def SO_DEBUG: int = 1;
export def SO_REUSEADDR: int = 2;
export def SO_TYPE: int = 3;
export def SO_ERROR: int = 4;
export def SO_DONTROUTE: int = 5;
export def SO_BROADCAST: int = 6;
export def SO_SNDBUF: int = 7;
export def SO_RCVBUF: int = 8;
export def SO_SNDBUFFORCE: int = 32;
export def SO_RCVBUFFORCE: int = 33;
export def SO_KEEPALIVE: int = 9;
export def SO_OOBINLINE: int = 10;
export def SO_NO_CHECK: int = 11;
export def SO_PRIORITY: int = 12;
export def SO_LINGER: int = 13;
export def SO_BSDCOMPAT: int = 14;
export def SO_REUSEPORT: int = 15;
export def SO_ATTACH_FILTER: int = 26;
export def SO_DETATCH_FILTER: int = 27;
export def SO_LOCK_FILTER: int = 44;

// the following differ on ppc
export def SO_PASSCRED: int = 16;
export def SO_PEERCRED: int = 17;
export def SO_RCVLOWAT: int = 18;
export def SO_SNDLOWAT: int = 19;
export def SO_RCVTIMEO_OLD: int = 20;
export def SO_SNDTIMEO_OLD: int = 21;
