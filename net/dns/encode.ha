use endian;
use errors;
use fmt;
use strings;

type encoder = struct {
	buf: []u8,
	offs: size,
};

// Converts a human-readable domain name (e.g. "example.org") into a DNS-ready
// name slice (e.g. ["example", "org"]). The slice returned must be freed by the
// caller, but the members of the slice themselves are borrowed from the input.
export fn parse_domain(in: str) []str = strings::split(in, ".");

// Converts a DNS name slice (e.g. ["example", "org"]) into a human-readable
// domain name (e.g. "example.org"). The return value must be freed by the
// caller.
export fn unparse_domain(in: []str) str = strings::join(".", in...);

// Encodes a DNS message, returning its size, or an error.
export fn encode(buf: []u8, msg: *message) (size | error) = {
	let enc = encoder { buf = buf, offs = 0z };
	encode_u16(&enc, msg.header.id)?;
	encode_u16(&enc, encode_op(&msg.header.op))?;
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

fn encode_labels(enc: *encoder, names: []str) (void | error) = {
	// TODO: Assert that the labels are all valid ASCII?
	for (let i = 0z; i < len(names); i += 1) {
		// XXX: Should I return an error instead of asserting?
		assert(len(names[i]) < 256);
		if (len(enc.buf) <= enc.offs + 1 + len(names[i])) {
			return errors::overflow;
		};
		encode_u8(enc, len(names[i]): u8)?;
		let label = fmt::bsprintf(enc.buf[enc.offs..], "{}", names[i]);
		enc.offs += len(label);
	};
};

fn question_encode(enc: *encoder, q: *question) (void | error) = {
	encode_labels(enc, q.qname)?;
	encode_u8(enc, 0)?;
	encode_u16(enc, q.qtype)?;
	encode_u16(enc, q.qclass)?;
};

fn rrecord_encode(enc: *encoder, r: *rrecord) (void | error) = {
	encode_labels(enc, r.name)?;
	encode_u8(enc, 0)?;
	encode_u16(enc, r.rtype)?;
	encode_u16(enc, r.class)?;
	encode_u32(enc, r.ttl)?;

	abort(); // TODO
};

fn encode_op(op: *op) u16 =
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
	let enc = encode_op(&opcode);
	let opcode2 = op { ... };
	decode_op(enc, &opcode2);
	assert(opcode.qr == opcode2.qr && opcode.opcode == opcode2.opcode &&
		opcode.aa == opcode2.aa && opcode.tc == opcode2.tc &&
		opcode.rd == opcode2.rd && opcode.ra == opcode2.ra &&
		opcode.rcode == opcode2.rcode);
};
