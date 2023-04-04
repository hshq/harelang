// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2022 Lassi Pulkkinen <lassi@pulk.fi>
use ascii;
use endian;
use fmt;
use net::ip;
use strings;

type decoder = struct {
	buf: []u8,
	cur: []u8,
};

// Decodes a DNS message, heap allocating the resources necessary to represent
// it in Hare's type system. The caller must use [[message_free]] to free the
// return value. To decode without use of the heap, see [[decoder_init]].
export fn decode(buf: []u8) (*message | format) = {
	let success = false;
	let msg = alloc(message { ... });
	defer if (!success) message_free(msg);
	let dec = decoder_init(buf);
	decode_header(&dec, &msg.header)?;
	for (let i = 0z; i < msg.header.qdcount; i += 1) {
		append(msg.questions, decode_question(&dec)?);
	};
	decode_rrecords(&dec, msg.header.ancount, &msg.answers)?;
	decode_rrecords(&dec, msg.header.nscount, &msg.authority)?;
	decode_rrecords(&dec, msg.header.arcount, &msg.additional)?;
	success = true;
	return msg;
};

fn decode_rrecords(
	dec: *decoder,
	count: u16,
	out: *[]rrecord,
) (void | format) = {
	for (let i = 0z; i < count; i += 1) {
		append(out, decode_rrecord(dec)?);
	};
};

fn decoder_init(buf: []u8) decoder = decoder {
	buf = buf,
	cur = buf,
	...
};

fn decode_u8(dec: *decoder) (u8 | format) = {
	if (len(dec.cur) < 1) {
		return format;
	};
	const val = dec.cur[0];
	dec.cur = dec.cur[1..];
	return val;
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

fn decode_header(dec: *decoder, head: *header) (void | format) = {
	head.id = decode_u16(dec)?;
	const rawop = decode_u16(dec)?;
	decode_op(rawop, &head.op);
	head.qdcount = decode_u16(dec)?;
	head.ancount = decode_u16(dec)?;
	head.nscount = decode_u16(dec)?;
	head.arcount = decode_u16(dec)?;
};

fn decode_op(in: u16, out: *op) void = {
	out.qr = ((in & 0b1000000000000000) >> 15): qr;
	out.opcode = ((in & 0b01111000000000u16) >> 11): opcode;
	out.aa = in & 0b0000010000000000u16 != 0;
	out.tc = in & 0b0000001000000000u16 != 0;
	out.rd = in & 0b0000000100000000u16 != 0;
	out.ra = in & 0b0000000010000000u16 != 0;
	out.rcode = (in & 0b1111): rcode;
};

fn decode_name(dec: *decoder) ([]str | format) = {
	let success = false;
	let names: []str = [];
	defer if (!success) strings::freeall(names);
	let totalsize = 0z;
	let sub = decoder {
		buf = dec.buf,
		...
	};
	for (let i = 0z; i < len(dec.buf); i += 2) {
		if (len(dec.cur) < 1) {
			return format;
		};
		const z = dec.cur[0];
		if (z & 0b11000000 == 0b11000000) {
			const offs = decode_u16(dec)? & ~0b1100000000000000u16;
			if (len(dec.buf) < offs) {
				return format;
			};
			sub.cur = dec.buf[offs..];
			dec = &sub;
			continue;
		};
		dec.cur = dec.cur[1..];
		totalsize += z + 1;
		if (totalsize > 255) {
			return format;
		};
		if (z == 0) {
			success = true;
			return names;
		};

		if (len(dec.cur) < z) {
			return format;
		};
		const name = match (strings::fromutf8(dec.cur[..z])) {
		case let name: str =>
			yield name;
		case =>
			return format;
		};
		dec.cur = dec.cur[z..];
		if (!ascii::validstr(name)) {
			return format;
		};

		append(names, strings::dup(name));
	};
	return format;
};

fn decode_question(dec: *decoder) (question | format) = {
	let success = false;
	const qname = decode_name(dec)?;
	defer if (!success) strings::freeall(qname);
	const qtype = decode_u16(dec)?: qtype;
	const qclass = decode_u16(dec)?: qclass;
	success = true;
	return question {
		qname = qname,
		qtype = qtype,
		qclass = qclass,
	};
};

fn decode_rrecord(dec: *decoder) (rrecord | format) = {
	let success = false;
	const name = decode_name(dec)?;
	defer if (!success) strings::freeall(name);
	const rtype = decode_u16(dec)?: rtype;
	const class = decode_u16(dec)?: class;
	const ttl = decode_u32(dec)?;
	const rlen = decode_u16(dec)?;
	const rdata = decode_rdata(dec, rtype, rlen)?;
	success = true;
	return rrecord {
		name = name,
		rtype = rtype,
		class = class,
		ttl = ttl,
		rdata = rdata
	};
};

fn decode_rdata(dec: *decoder, rtype: rtype, rlen: size) (rdata | format) = {
	if (len(dec.cur) < rlen) {
		return format;
	};
	let sub = decoder {
		cur = dec.cur[..rlen],
		buf = dec.buf,
	};
	dec.cur = dec.cur[rlen..];
	switch (rtype) {
	case rtype::A =>
		return decode_a(&sub);
	case rtype::AAAA =>
		return decode_aaaa(&sub);
	case rtype::CNAME =>
		return decode_cname(&sub);
	case rtype::MX =>
		return decode_mx(&sub);
	case rtype::TXT =>
		return decode_txt(&sub);
	case =>
		return sub.cur: unknown_rdata;
	};
};

fn decode_a(dec: *decoder) (rdata | format) = {
	if (len(dec.cur) < 4) {
		return format;
	};
	let ip: ip::addr4 = [0...];
	ip[..] = dec.cur[..4];
	dec.cur = dec.cur[4..];
	return ip: a;
};

fn decode_aaaa(dec: *decoder) (rdata | format) = {
	if (len(dec.cur) < 16) {
		return format;
	};
	let ip: ip::addr6 = [0...];
	ip[..] = dec.cur[..16];
	dec.cur = dec.cur[16..];
	return ip: aaaa;
};

fn decode_cname(dec: *decoder) (rdata | format) = {
	return cname {
		name = decode_name(dec)?,
	};
};

fn decode_mx(dec: *decoder) (rdata | format) = {
	return mx {
		priority = decode_u16(dec)?,
		name = decode_name(dec)?,
	};
};

fn decode_txt(dec: *decoder) (rdata | format) = {
	let success = false;
	let items: txt = [];
	defer if (!success) bytes_free(items);
	for (len(dec.cur) != 0) {
		const ln = decode_u8(dec)?;
		if (len(dec.cur) < ln) {
			return format;
		};
		let item: []u8 = [];
		append(item, dec.cur[..ln]...);
		dec.cur = dec.cur[ln..];
		append(items, item);
	};
	success = true;
	return items;
};

// TODO: Expand breadth of supported rdata decoders
