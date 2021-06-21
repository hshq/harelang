// Record type
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
	DNSKEY = 48,
};

// Question type
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
	DNSKEY = 48,
	// ...
	AXFR = 252,
	// *
	ALL = 255,
};

// Class type
export type class = enum u16 {
	IN = 1,
	CS = 2,
	CH = 3,
	HS = 4,
};

// Query class
export type qclass = enum u16 {
	IN = 1,
	CS = 2,
	CH = 3,
	HS = 4,
	// *
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

// Operation requested from resolver
export type opcode = enum u8 {
	QUERY = 0,
	IQUERY = 1,
	STATUS = 2,
};

// Response code from resolver
export type rcode = enum u8 {
	NO_ERROR = 0,
	FMT_ERROR = 1,
	SERVER_FAILURE = 2,
	NAME_ERROR = 3,
	NOT_IMPLEMENTED = 4,
	REFUSED = 5,
};

// Operational information for this message.
export type op = struct {
	// Is this a query or a response?
	qr: qr,
	// Operation code
	opcode: opcode,
	// Authoratative answer bit
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
	rdata: []u8,
};

// A DNS message, Hare representation. See [[encode]] and [[decode]] for the DNS
// representation.
export type message = struct {
	header: header,
	questions: []question,
	answers: []rrecord,
	authority: []rrecord,
	additional: []rrecord,
};

fn strings_free(in: []str) void = {
	for (let i = 0z; i < len(in); i += 1) {
		free(in[i]);
	};
	free(in);
};

// Frees a [[message]] and the resources associated with it.
export fn message_free(msg: *message) void = {
	for (let i = 0z; i < len(msg.questions); i += 1) {
		strings_free(msg.questions[i].qname);
	};
	free(msg.questions);

	for (let i = 0z; i < len(msg.answers); i += 1) {
		strings_free(msg.answers[i].name);
		free(msg.answers[i].rdata);
	};
	free(msg.answers);

	for (let i = 0z; i < len(msg.authority); i += 1) {
		strings_free(msg.authority[i].name);
		free(msg.authority[i].rdata);
	};
	free(msg.authority);

	for (let i = 0z; i < len(msg.additional); i += 1) {
		strings_free(msg.additional[i].name);
		free(msg.additional[i].rdata);
	};
	free(msg.additional);

	free(msg);
};