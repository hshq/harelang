// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
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
	let msg = alloc(message { ... });
	let dec = decoder_init(buf);
	decode_header(&dec, &msg.header)?;
	for (let i = 0z; i < msg.header.qdcount; i += 1) {
		append(msg.questions, decode_question(&dec)?);
	};
	decode_rrecords(&dec, msg.header.ancount, &msg.answers)?;
	decode_rrecords(&dec, msg.header.nscount, &msg.authority)?;
	decode_rrecords(&dec, msg.header.arcount, &msg.additional)?;
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
	let names: []str = [];
	for (true) {
		const z = dec.cur[0];
		if (z & 0b11000000 == 0b11000000) {
			const offs = decode_u16(dec)? & ~0b1100000000000000u16;
			const sub = decoder {
				buf = dec.buf,
				cur = dec.buf[offs..],
				...
			};
			append(names, decode_name(&sub)?...);
			break;
		};
		dec.cur = dec.cur[1..];
		if (z == 0) {
			break;
		};

		const name = dec.cur[..z];
		dec.cur = dec.cur[z..];
		for (let i = 0z; i < len(name); i += 1) {
			if (!ascii::valid(name[i]: u32: rune)) {
				return format;
			};
		};

		append(names, strings::dup(strings::fromutf8(name)));
	};
	return names;
};

fn decode_question(dec: *decoder) (question | format) = {
	return question {
		qname = decode_name(dec)?,
		qtype = decode_u16(dec)?: qtype,
		qclass = decode_u16(dec)?: qclass,
	};
};

fn decode_rrecord(dec: *decoder) (rrecord | format) = {
	const name = decode_name(dec)?;
	const rtype = decode_u16(dec)?: rtype;
	const class = decode_u16(dec)?: class;
	const ttl = decode_u32(dec)?;
	const rlen = decode_u16(dec)?;
	const rdata = decode_rdata(dec, rtype, rlen)?;
	return rrecord {
		name = name,
		rtype = rtype,
		class = class,
		ttl = ttl,
		rdata = rdata
	};
};

fn decode_rdata(dec: *decoder, rtype: rtype, rlen: size) (rdata | format) = {
	switch (rtype) {
	case rtype::A =>
		return decode_a(dec);
	case rtype::AAAA =>
		return decode_aaaa(dec);
	case rtype::MX =>
		return decode_mx(dec);
	case rtype::TXT =>
		return decode_txt(dec);
	case =>
		let buf = dec.cur[..rlen];
		dec.cur = dec.cur[rlen..];
		return buf: unknown_rdata;
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

fn decode_mx(dec: *decoder) (rdata | format) = {
	return mx {
		priority = decode_u16(dec)?,
		name = decode_name(dec)?,
	};
};

fn decode_txt(dec: *decoder) (rdata | format) = {
	let items: txt = [];
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
	return items;
};

// TODO: Expand breadth of supported rdata decoders
