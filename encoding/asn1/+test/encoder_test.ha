// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use bytes;
use errors;
use io;
use memio;
use os;
use strings;
use time::date;
use types;


@test fn write_id() void = {
	let buf = memio::dynamic();
	defer io::close(&buf)!;
	let e = derencoder(&buf);

	write_fixedprim(&e, class::UNIVERSAL, 0x2aa, [0x00])!;
	encode(&e)!;
	assert(bytes::equal([0x1f, 0x85, 0x2a, 0x01, 0x00],
			memio::buffer(&buf)));

	io::seek(&buf, 0, io::whence::SET)!;
	let d = derdecoder(&buf);
	let h = peek(&d)!;
	assert(h.tagid == 0x2aa);

	let buf = memio::dynamic();
	defer io::close(&buf)!;
	let e = derencoder(&buf);

	write_fixedprim(&e, class::UNIVERSAL, types::U32_MAX, [0x00])!;
	encode(&e)!;
	assert(bytes::equal([0x1f, 0x8f, 0xff, 0xff, 0xff, 0x7f, 0x01, 0x00],
			memio::buffer(&buf)));

	io::seek(&buf, 0, io::whence::SET)!;
	let d = derdecoder(&buf);
	let h = peek(&d)!;
	assert(h.tagid == types::U32_MAX);
};

@test fn write_prim() void = {
	let buf = memio::dynamic();
	defer io::close(&buf)!;
	let dest = memio::dynamic();
	defer io::close(&dest)!;

	let enc = derencoder(&buf);

	create_prim(&enc, class::UNIVERSAL, utag::INTEGER)!;
	write(&enc, [0x01, 0x05, 0x07])!;
	finish_prim(&enc);

	assert(encodeto(&enc, &dest)! == 5);

	assert(bytes::equal(memio::buffer(&dest), [
		0x02, 0x03, 0x01, 0x05, 0x07
	]));
};

@test fn encode_dsz() void = {
	assert(bytes::equal([0x7f], encode_dsz(0x7f)));
	assert(bytes::equal([0x81, 0x8f], encode_dsz(0x8f)));
	assert(bytes::equal([0x81, 0xff], encode_dsz(0xff)));
	assert(bytes::equal([0x82, 0x01, 0x00], encode_dsz(0x100)));
};

@test fn write_seq() void = {
	let buf = memio::dynamic();
	defer io::close(&buf)!;
	let dest = memio::dynamic();
	defer io::close(&dest)!;

	let enc = derencoder(&buf);

	create_seq(&enc)!;
	write_bool(&enc, false)!;
	create_seq(&enc)!;
	write_int(&enc, [0x01, 0x02, 0x03])!;
	finish_seq(&enc);
	finish_seq(&enc);
	assert(encodeto(&enc, &dest)! == 12);

	assert(bytes::equal(memio::buffer(&dest), [
		0x30, 0x0a, // seq
		0x01, 0x01, 0x00, // bool
		0x30, 0x05, // seq
		0x02, 0x03, 0x01, 0x02, 0x03, // int
	]));
};

@test fn write_bool() void = {
	let dest = memio::dynamic();
	defer io::close(&dest)!;

	let buf = memio::dynamic();
	defer io::close(&buf)!;
	let enc = derencoder(&buf);

	write_bool(&enc, true)!;
	encodeto(&enc, &dest)!;

	assert(bytes::equal(memio::buffer(&dest), [0x01, 0x01, 0xff]));
};

@test fn write_int() void = {
	let dest = memio::dynamic();
	defer io::close(&dest)!;
	let buf = memio::dynamic();
	defer io::close(&buf)!;

	let enc = derencoder(&buf);

	write_int(&enc, [0x00, 0x00, 0x00, 0x00, 0x80])!;
	encodeto(&enc, &dest)!;

	assert(bytes::equal(memio::buffer(&dest), [0x02, 0x02, 0x00, 0x80]));

	memio::reset(&dest);
	memio::reset(&buf);
	let enc = derencoder(&buf);

	write_int(&enc, [0xff, 0xff, 0xff, 0x80, 0x10])!;
	encodeto(&enc, &dest)!;

	assert(bytes::equal(memio::buffer(&dest), [0x02, 0x02, 0x80, 0x10]));

	memio::reset(&dest);
	memio::reset(&buf);
	let enc = derencoder(&buf);

	write_int(&enc, [0x00, 0x00, 0x00])!;
	encodeto(&enc, &dest)!;

	assert(bytes::equal(memio::buffer(&dest), [0x02, 0x01, 0x00]));

	memio::reset(&dest);
	memio::reset(&buf);
	let enc = derencoder(&buf);

	write_uint(&enc, [0x8f, 0x01])!;
	encodeto(&enc, &dest)!;

	assert(bytes::equal(memio::buffer(&dest), [0x02, 0x03, 0x00, 0x8f, 0x01]));
};
