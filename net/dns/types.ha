// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Jonathan Halmen <slowjo@halmen.xyz>
// (c) 2022 Lassi Pulkkinen <lassi@pulk.fi>
use net::ip;
use strings;

// Record type.
export type rtype = enum u16 {
	A = 1,
	NS = 2,
	CNAME = 5,
	SOA = 6,
	PTR = 12,
	MX = 15,
	TXT = 16,
	AAAA = 28,
	SRV = 33,
	SSHFP = 44,
	DNSKEY = 48,
	TSIG = 250,
	CAA = 257,
};

// Question type (superset of [[rtype]]).
export type qtype = enum u16 {
	A = 1,
	NS = 2,
	CNAME = 5,
	SOA = 6,
	PTR = 12,
	MX = 15,
	TXT = 16,
	AAAA = 28,
	SRV = 33,
	SSHFP = 44,
	DNSKEY = 48,
	// ...
	AXFR = 252,
	// *
	ALL = 255,
	CAA = 257,
};

// Class type (e.g. Internet).
export type class = enum u16 {
	IN = 1,
	CS = 2,
	CH = 3,
	HS = 4,
};

// Query class (superset of [[class]]).
export type qclass = enum u16 {
	IN = 1,
	CS = 2,
	CH = 3,
	HS = 4,
	// *
	NONE = 254,
	ANY = 255,
};

// DNS message header.
export type header = struct {
	id: u16,
	op: op,
	// Number of questions
	qdcount: u16,
	// Number of answers
	ancount: u16,
	// Number of name servers
	nscount: u16,
	// Number of additional resources
	arcount: u16,
};

// Bit indicating if a header precedes a query or response.
export type qr = enum u8 {
	QUERY = 0,
	RESPONSE = 1,
};

// Operation requested from resolver.
export type opcode = enum u8 {
	QUERY = 0,
	IQUERY = 1,
	STATUS = 2,
	UPDATE = 5,
};

// Response code from resolver.
export type rcode = enum u8 {
	NOERROR = 0,
	FORMERR = 1,
	SERVFAIL = 2,
	NXDOMAIN = 3,
	NOTIMP = 4,
	REFUSED = 5,
	// RFC 2136 UPDATE
	YXDOMAIN = 6,
	YXRRSET = 7,
	NXRRSET = 8,
	NOTAUTH = 9,
	NOTZONE = 10,
	// RFC 2845 TSIG
	BADSIG = 16,
	BADKEY = 17,
	BADTIME = 18,
};

// Operational information for this message.
export type op = struct {
	// Is this a query or a response?
	qr: qr,
	// Operation code
	opcode: opcode,
	// Authoritative answer bit
	aa: bool,
	// Truncation bit
	tc: bool,
	// Recursion desired bit
	rd: bool,
	// Recursion available bit
	ra: bool,
	// Response code
	rcode: rcode,
};

// A question section item.
export type question = struct {
	qname: []str,
	qtype: qtype,
	qclass: qclass,
};

// A resource record item.
export type rrecord = struct {
	name: []str,
	rtype: rtype,
	class: class,
	ttl: u32,
	rdata: rdata,
};

// An A record.
export type a = ip::addr4;

// An AAAA record.
export type aaaa = ip::addr6;

// A CAA record.
export type caa = struct {
	flags: u8,
	tag: str,
	value: str,
};

// A CNAME record.
export type cname = struct {
	name: []str,
};

// An MX record.
export type mx = struct {
	priority: u16,
	name: []str,
};

// An NS record.
export type ns = struct {
	name: []str,
};

// A PTR record.
export type ptr = struct {
	name: []str,
};

// An SOA record.
export type soa = struct {
	mname: []str,
	rname: []str,
	serial: u32,
	refresh: u32,
	retry: u32,
	expire: u32,
};

// An SRV record.
export type srv = struct {
	priority: u16,
	weight: u16,
	port: u16,
	target: []str,
};

// An SSHFP record.
export type sshfp = struct {
	algorithm: u8,
	fp_type: u8,
	fingerprint: []u8,
};

// A TSIG record.
export type tsig = struct {
	algorithm: []str,
	time_signed: u64,
	fudge: u16,
	mac_len: u16,
	mac: []u8,
	orig_id: u16,
	error: u16,
	other_len: u16,
	other_data: []u8,
};

// A TXT record.
export type txt = [][]u8;

// The raw rdata field for an [[rrecord]] with an unknown [[rtype]].
export type unknown_rdata = []u8;

// Tagged union of supported rdata types.
export type rdata = (a | aaaa | caa | cname | mx | ns | ptr | soa | srv
	| sshfp | tsig | txt | unknown_rdata);

// A DNS message, Hare representation. See [[encode]] and [[decode]] for the DNS
// representation.
export type message = struct {
	header: header,
	questions: []question,
	answers: []rrecord,
	authority: []rrecord,
	additional: []rrecord,
};

// Frees a [[message]] and the resources associated with it.
export fn message_free(msg: *message) void = {
	for (let i = 0z; i < len(msg.questions); i += 1) {
		strings::freeall(msg.questions[i].qname);
	};
	free(msg.questions);

	rrecords_free(msg.answers);
	rrecords_free(msg.authority);
	rrecords_free(msg.additional);

	free(msg);
};

fn bytes_free(in: [][]u8) void = {
	for (let i = 0z; i < len(in); i += 1) {
		free(in[i]);
	};
	free(in);
};

fn rrecords_free(rrs: []rrecord) void = {
	for (let i = 0z; i < len(rrs); i += 1) {
		rrecord_finish(&rrs[i]);
	};
	free(rrs);
};

fn rrecord_finish(rr: *rrecord) void = {
	strings::freeall(rr.name);
	match (rr.rdata) {
	case let cn: cname =>
		strings::freeall(cn.name);
	case let ca: caa =>
		free(ca.tag);
		free(ca.value);
	case let mx: mx =>
		strings::freeall(mx.name);
	case let ns: ns =>
		strings::freeall(ns.name);
	case let ptr: ptr =>
		strings::freeall(ptr.name);
	case let so: soa =>
		strings::freeall(so.mname);
		strings::freeall(so.rname);
	case let sr: srv =>
		strings::freeall(sr.target);
	case let sf: sshfp =>
		free(sf.fingerprint);
	case let ts: tsig =>
		strings::freeall(ts.algorithm);
		free(ts.mac);
		free(ts.other_data);
	case let tx: txt =>
		bytes_free(tx: [][]u8);
	case => void;
	};
};
