// TODO: Refactor me
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
	for (let i = 0z; i < len(msg.answers); i += 1) {
		z += rrecord_encode(buf[z..], &msg.answers[i]);
	};
	for (let i = 0z; i < len(msg.authority); i += 1) {
		z += rrecord_encode(buf[z..], &msg.authority[i]);
	};
	for (let i = 0z; i < len(msg.additional); i += 1) {
		z += rrecord_encode(buf[z..], &msg.additional[i]);
	};

	return z;
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

fn rrecord_encode(buf: []u8, r: *rrecord) size = {
	// TODO: Assert that the labels are all valid ASCII?
	let z = 0z;
	for (let i = 0z; i < len(r.name); i += 1) {
		assert(len(r.name[i]) < 256);
		buf[z] = len(r.name[i]): u8;
		z += 1;
		let label = fmt::bsprintf(buf[z..], "{}", r.name[i]);
		z += len(label);
	};
	// Root
	buf[z] = 0;
	z += 1;

	endian::beputu16(buf[z..], r.rtype);
	z += 2;
	endian::beputu16(buf[z..], r.class);
	z += 2;
	endian::beputu32(buf[z..], r.ttl);
	z += 4;

	assert(len(r.rdata) <= 0xFFFF);
	endian::beputu16(buf[z..], len(r.rdata): u16);
	z += 2;

	buf[z..len(r.rdata)] = r.rdata[..];
	z += len(r.rdata);
	return z;
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
