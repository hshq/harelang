// TODO: Refactor me
use errors;
use endian;
use fmt;

type encoder = struct {
	buf: []u8,
	offs: size,
};

// Encodes a DNS message, returning its size, or an error.
export fn encode(buf: []u8, msg: *message) (size | error) = {
	let enc = encoder { buf = buf, offs = 0z };
	encode_u16(&enc, msg.header.id)?;
	encode_u16(&enc, op_encode(&msg.header.op))?;
	encode_u16(&enc, msg.header.qdcount)?;
	encode_u16(&enc, msg.header.ancount)?;
	encode_u16(&enc, msg.header.nscount)?;
	encode_u16(&enc, msg.header.arcount)?;

	for (let i = 0z; i < len(msg.questions); i += 1) {
		question_encode(&enc, &msg.questions[i])?;
	};
	for (let i = 0z; i < len(msg.answers); i += 1) {
		rrecord_encode(&enc, &msg.answers[i])?;
	};
	for (let i = 0z; i < len(msg.authority); i += 1) {
		rrecord_encode(&enc, &msg.authority[i])?;
	};
	for (let i = 0z; i < len(msg.additional); i += 1) {
		rrecord_encode(&enc, &msg.additional[i])?;
	};

	return enc.offs;
};

fn encode_u8(enc: *encoder, val: u8) (void | error) = {
	if (len(enc.buf) <= enc.offs + 1) {
		return errors::overflow;
	};
	enc.buf[enc.offs] = val;
	enc.offs += 1;
};

fn encode_u16(enc: *encoder, val: u16) (void | error) = {
	if (len(enc.buf) <= enc.offs + 2) {
		return errors::overflow;
	};
	endian::beputu16(enc.buf[enc.offs..], val);
	enc.offs += 2;
};

fn encode_u32(enc: *encoder, val: u32) (void | error) = {
	if (len(enc.buf) <= enc.offs + 4) {
		return errors::overflow;
	};
	endian::beputu32(enc.buf[enc.offs..], val);
	enc.offs += 4;
};

fn question_encode(enc: *encoder, q: *question) (void | error) = {
	// TODO: Assert that the labels are all valid ASCII?
	for (let i = 0z; i < len(q.qname); i += 1) {
		assert(len(q.qname[i]) < 256);
		if (len(enc.buf) <= enc.offs + 1 + len(q.qname[i])) {
			return errors::overflow;
		};
		encode_u8(enc, len(q.qname[i]): u8)?;
		let label = fmt::bsprintf(enc.buf[enc.offs..], "{}", q.qname[i]);
		enc.offs += len(label);
	};
	encode_u8(enc, 0)?;
	encode_u16(enc, q.qtype)?;
	encode_u16(enc, q.qclass)?;
};

fn rrecord_encode(enc: *encoder, r: *rrecord) (void | error) = {
	// TODO: Assert that the labels are all valid ASCII?
	for (let i = 0z; i < len(r.name); i += 1) {
		assert(len(r.name[i]) < 256);
		if (len(enc.buf) <= enc.offs + 1 + len(r.name[i])) {
			return errors::overflow;
		};
		encode_u8(enc, len(r.name[i]): u8)?;
		let label = fmt::bsprintf(enc.buf[enc.offs..], "{}", r.name[i]);
		enc.offs += len(label);
	};
	encode_u8(enc, 0)?;
	encode_u16(enc, r.rtype)?;
	encode_u16(enc, r.class)?;
	encode_u32(enc, r.ttl)?;

	assert(len(r.rdata) <= 0xFFFF);
	encode_u16(enc, len(r.rdata): u16)?;

	if (len(enc.buf) <= enc.offs + len(r.rdata)) {
		return errors::overflow;
	};

	enc.buf[enc.offs..len(r.rdata)] = r.rdata[..];
	enc.offs += len(r.rdata);
};

fn op_encode(op: *op) u16 =
	(op.qr: u16 << 15u16) | 
	(op.opcode: u16 << 11u16) |
	(if (op.aa) 0b0000010000000000u16 else 0u16) |
	(if (op.tc) 0b0000001000000000u16 else 0u16) |
	(if (op.rd) 0b0000000100000000u16 else 0u16) |
	(if (op.ra) 0b0000000010000000u16 else 0u16) |
	op.rcode: u16;

@test fn opcode() void = {
	let opcode = op {
		qr = qr::RESPONSE,
		opcode = opcode::IQUERY,
		aa = false,
		tc = true,
		rd = false,
		ra = true,
		rcode = rcode::SERVER_FAILURE,
	};
	let enc = op_encode(&opcode);
	let opcode2 = op { ... };
	op_decode(enc, &opcode2);
	assert(opcode.qr == opcode2.qr && opcode.opcode == opcode2.opcode &&
		opcode.aa == opcode2.aa && opcode.tc == opcode2.tc &&
		opcode.rd == opcode2.rd && opcode.ra == opcode2.ra &&
		opcode.rcode == opcode2.rcode);
};
