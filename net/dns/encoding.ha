// TODO: Error handling
use endian;
use fmt;

// Encodes a DNS message, returning its size.
export fn encode(buf: []u8, msg: *message) size = {
	let z = 0z;
	endian::beputu16(buf[z..], msg.header.id);
	z += 2;
	endian::beputu16(buf[z..], op_encode(&msg.header.op));
	z += 2;
	endian::beputu16(buf[z..], msg.header.qdcount);
	z += 2;
	endian::beputu16(buf[z..], msg.header.ancount);
	z += 2;
	endian::beputu16(buf[z..], msg.header.nscount);
	z += 2;
	endian::beputu16(buf[z..], msg.header.arcount);
	z += 2;

	for (let i = 0z; i < len(msg.questions); i += 1) {
		z += question_encode(buf[z..], &msg.questions[i]);
	};

	return z;
};

// Decodes a DNS message.
export fn decode(buf: []u8, msg: *message) void = {
	let z = 0z;
	msg.header.id = endian::begetu16(buf[z..]);
	z += 2;
	let rawop = endian::begetu16(buf[z..]);
	op_decode(rawop, &msg.header.op);
	z += 2;
	msg.header.qdcount = endian::begetu16(buf[z..]);
	z += 2;
	msg.header.ancount = endian::begetu16(buf[z..]);
	z += 2;
	msg.header.nscount = endian::begetu16(buf[z..]);
	z += 2;
	msg.header.arcount = endian::begetu16(buf[z..]);
	z += 2;
};

fn question_encode(buf: []u8, q: *question) size = {
	// TODO: Assert that the labels are all valid ASCII?
	let z = 0z;
	for (let i = 0z; i < len(q.qname); i += 1) {
		assert(len(q.qname[i]) < 256);
		buf[z] = len(q.qname[i]): u8;
		z += 1;
		let label = fmt::bsprintf(buf[z..], "{}", q.qname[i]);
		z += len(label);
	};
	// Root
	buf[z] = 0;
	z += 1;
	// Trailers
	endian::beputu16(buf[z..], q.qtype);
	z += 2;
	endian::beputu16(buf[z..], q.qclass);
	z += 2;
	return z;
};

fn op_encode(op: *op) u16 = endian::htonu16(
	(op.qr: u16 << 15u16) | 
	(op.opcode: u16 << 11u16) |
	(if (op.aa) 0b0000010000000000u16 else 0u16) |
	(if (op.tc) 0b0000001000000000u16 else 0u16) |
	(if (op.rd) 0b0000000100000000u16 else 0u16) |
	(if (op.ra) 0b0000000010000000u16 else 0u16) |
	op.rcode: u16);

fn op_decode(in: u16, out: *op) void = {
	let in = endian::ntohu16(in);
	out.qr = ((in & 0b1000000000000000) >> 15): qr;
	out.opcode = ((in & 0b01111000000000u16) >> 11): opcode;
	out.aa = in & 0b0000010000000000u16 != 0;
	out.tc = in & 0b0000001000000000u16 != 0;
	out.rd = in & 0b0000000100000000u16 != 0;
	out.ra = in & 0b0000000010000000u16 != 0;
	out.rcode = (in & 0b1111): rcode;
};

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
