use ascii;
use endian;
use net::ip;
use strings;

export type decoder = struct {
	buf: []u8,
	cur: []u8,
	qdcount: u16,
	ancount: u16,
	nscount: u16,
	arcount: u16,
};

// Decodes a DNS message, heap allocating the resources necessary to represent
// it in Hare's type system. The caller must use [[message_free]] to free the
// return value. To decode without use of the heap, see [[decoder_init]].
export fn decode(buf: []u8) (*message | format) = {
	let msg = message { ... };
	let dec = decoder_init(buf);
	decode_header(&dec, &msg.header)?;

	for (let i = 0z; i < msg.header.qdcount; i += 1) {
		let q = question { ... };
		let names = decode_question(&dec, &q)?;

		for (let i = 0; len(names) != 0; i += 1) {
			let ns = decode_name(&dec, names)!;
			names = ns.0;
			append(q.qname, strings::dup(ns.1));
		};

		append(msg.questions, q);
	};

	decode_rrecords(&dec, msg.header.ancount, &msg.answers)?;
	decode_rrecords(&dec, msg.header.nscount, &msg.authority)?;
	decode_rrecords(&dec, msg.header.arcount, &msg.additional)?;
	return alloc(msg);
};

fn decode_rrecords(
	dec: *decoder,
	count: u16,
	out: *[]rrecord,
) (void | format) = {
	for (let i = 0z; i < count; i += 1) {
		let r = rrecord { ... };
		let names = decode_rrecord(dec, &r)?;
		let rdata = r.rdata;
		r.rdata = [];
		append(r.rdata, rdata...);

		for (let i = 0; len(names) != 0; i += 1) {
			let ns = decode_name(dec, names)!;
			names = ns.0;
			append(r.name, strings::dup(ns.1));
		};

		append(*out, r);
	};
};

// Initializes a DNS message decoder. All storaged used by the decoder is either
// stack-allocated, provided by the caller, or borrowed from the input buffer.
//
// Call [[decode_header]] next.
export fn decoder_init(buf: []u8) decoder = decoder {
	buf = buf,
	cur = buf,
	...
};

fn decode_u16(dec: *decoder) (u16 | format) = {
	if (len(dec.cur) < 2) {
		return format;
	};
	const val = endian::begetu16(dec.cur);
	dec.cur = dec.cur[2..];
	return val;
};

fn decode_u32(dec: *decoder) (u32 | format) = {
	if (len(dec.cur) < 4) {
		return format;
	};
	const val = endian::begetu32(dec.cur);
	dec.cur = dec.cur[4..];
	return val;
};

// Decodes a DNS message's header and advances the decoder to the
// variable-length section of the message. Following this call, the user should
// call [[decode_question]] for each question given by the header's qdcount,
// then [[decode_rrecord]] for each resource record given by the ancount,
// nscount, and arcount fields, respectively.
export fn decode_header(dec: *decoder, head: *header) (void | format) = {
	head.id = decode_u16(dec)?;
	let rawop = decode_u16(dec)?;
	op_decode(rawop, &head.op);
	head.qdcount = decode_u16(dec)?;
	head.ancount = decode_u16(dec)?;
	head.nscount = decode_u16(dec)?;
	head.arcount = decode_u16(dec)?;
	dec.qdcount = head.qdcount;
	dec.ancount = head.ancount;
	dec.nscount = head.nscount;
	dec.arcount = head.arcount;
};

fn op_decode(in: u16, out: *op) void = {
	out.qr = ((in & 0b1000000000000000) >> 15): qr;
	out.opcode = ((in & 0b01111000000000u16) >> 11): opcode;
	out.aa = in & 0b0000010000000000u16 != 0;
	out.tc = in & 0b0000001000000000u16 != 0;
	out.rd = in & 0b0000000100000000u16 != 0;
	out.ra = in & 0b0000000010000000u16 != 0;
	out.rcode = (in & 0b1111): rcode;
};

// Partially decodes a [[question]] and advances the decoder. Returns a slice
// representing the name field, which can be passed to [[decode_name]] to
// interpret.
export fn decode_question(dec: *decoder, q: *question) ([]u8 | format) = {
	let name = extract_name(dec)?;
	q.qtype = decode_u16(dec)?: qtype;
	q.qclass = decode_u16(dec)?: qclass;
	return name;
};

// Partially decodes a [[rrecord]] and advances the decoder. Returns a slice
// representing the name field, which can be passed to [[decode_name]] to
// interpret.
export fn decode_rrecord(dec: *decoder, r: *rrecord) ([]u8 | format) = {
	let name = extract_name(dec)!;
	r.rtype = decode_u16(dec)!: rtype;
	r.class = decode_u16(dec)!: class;
	r.ttl = decode_u32(dec)!;
	let rdz = decode_u16(dec)!;
	r.rdata = dec.cur[..rdz];
	dec.cur = dec.cur[rdz..];
	return name;
};

fn extract_name(dec: *decoder) ([]u8 | format) = {
	if (dec.cur[0] & 0b11000000 == 0b11000000) {
		const name = dec.cur[..2];
		dec.cur = dec.cur[2..];
		return name;
	};
	for (let i = 0z; i < len(dec.cur); i += 1) {
		let z = dec.cur[i];
		if (z == 0) {
			const name = dec.cur[..i + 1];
			dec.cur = dec.cur[i + 1..];
			return name;
		};
		i += z;
	};
	return format;
};

// Decodes a name from a question or resource record, returning the decoded name
// and the remainder of the buffer. The caller should pass the returned buffer
// into decode_name again to retrieve the next name. When the return value is an
// empty string, all of the names have been decoded. It is a programming error
// to call decode_name again after this, and the program will abort.
export fn decode_name(dec: *decoder, buf: []u8) (([]u8, str) | format) = {
	let z = buf[0];
	if (z == 0) {
		return ([]: []u8, "");
	};
	if (z & 0b11000000 == 0b11000000) {
		let offs = endian::begetu16(buf) & ~0b1100000000000000u16;
		return decode_name(dec, dec.buf[offs..]);
	};
	let name = buf[1..z + 1];
	buf = buf[z + 1..];
	for (let i = 0z; i < len(name); i += 1) {
		if (!ascii::isascii(name[i]: u32: rune)) {
			return format;
		};
	};
	return (buf, strings::fromutf8(name));
};

// Decodes the rdata field of a [[rrecord]]. The return value is borrowed from
// the rdata buffer.
export fn decode_rdata(rr: *rrecord) (ip::addr | format) = {
	return switch (rr.rtype) {
		rtype::A => decode_a(rr.rdata)?: ip::addr,
		rtype::AAAA => decode_aaaa(rr.rdata)?: ip::addr,
		* => format,
	};
};

// Decodes the rdata field of an A (address) record. The return value is
// borrowed from the rdata buffer.
export fn decode_a(rdata: []u8) (ip::addr4 | format) = {
	if (len(rdata) != 4) {
		return format;
	};
	let ip: ip::addr4 = [0...];
	ip[..] = rdata[..];
	return ip;
};

// Decodes the rdata field of an AAAA (address) record. The return value is
// borrowed from the rdata buffer.
export fn decode_aaaa(rdata: []u8) (ip::addr6 | format) = {
	if (len(rdata) != 8) {
		return format;
	};
	let ip: ip::addr6 = [0...];
	ip[..] = rdata[..];
	return ip;
};

// Decodes the rdata field of an MX (mail exchange) record, returning the
// priority and the name. See [[decode_name]] to decode the name. The return
// value is borrowed from the rdata buffer.
export fn decode_mx(rdata: []u8) ((u16, []u8) | format) = {
	if (len(rdata) < 2) {
		return format;
	};
	let prio = endian::begetu16(rdata);
	return (prio, rdata[2..]);
};

// TODO: Expand breadth of supported rdata decoders
