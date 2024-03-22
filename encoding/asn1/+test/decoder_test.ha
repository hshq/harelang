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


// XXX: would be nice to just declare this as mem: memio::stream
let mem: nullable *memio::stream = null;
let rbuf: [os::BUFSZ]u8 = [0...];

fn d(i: []u8) decoder = {
	let buf = memio::fixed(i);
	let h = match (mem) {
	case null =>
		let h = alloc(buf);
		mem = h;
		yield h;
	case let m: *memio::stream =>
		*m = buf;
		yield m;
	};
	return derdecoder(h);
};

@fini fn freetdec() void = {
	match (mem) {
	case null => void;
	case let m: *memio::stream =>
		free(m);
		mem = null;
	};
};

@test fn parsetag() void = {
	assert((next(&d([0x02, 0x01]))!).class == class::UNIVERSAL);
	assert((next(&d([0x02, 0x01]))!).tagid == 0x02);
	assert((next(&d([0x1e, 0x01]))!).tagid == 0x1e);
	assert((next(&d([0x1f, 0x7f, 0x01]))!).tagid == 0x7f);
	assert((next(&d([0x1f, 0x81, 0x00, 0x01]))!).tagid == 0x80);

	assert((next(&d([0x1f, 0x8f, 0xff, 0xff, 0xff, 0x7f, 0x01]))!).tagid
		== types::U32_MAX);
	assert(next(&d([0x1f, 0x90, 0x80, 0x80, 0x80, 0x00, 0x01])) is invalid);
};

@test fn parselen() void = {
	assert(dsz(next(&d([0x02, 0x1]))!) == 1);
	assert(dsz(next(&d([0x02, 0x7f]))!) == 127);
	assert(dsz(next(&d([0x02, 0x81, 0x80]))!) == 128);

	// must use minimal amount of bytes for length encoding
	assert(next(&d([0x02, 0x81, 0x01, 0x01])) is invalid);
	assert(next(&d([0x02, 0x81, 0x7f])) is invalid);
	assert(next(&d([0x02, 0x82, 0x00, 0xff])) is invalid);

	// indefinite form is not allowed in DER
	assert(next(&d([0x02, 0x80, 0x01, 0x00, 0x00])) is invalid);
};

@test fn emptydata() void = {
	assert(read_bool(&d([])) is badformat);
	assert(open_set(&d([])) is badformat);
};

@test fn seq() void = {
	let dat: [_]u8 = [
		0x30, 0x0a, // seq
		0x01, 0x01, 0xff, // bool true
		0x30, 0x05, // seq
		0x30, 0x03, // seq
		0x01, 0x01, 0x00, // bool false
	];

	let dc = &d(dat);
	open_seq(dc)!;
	assert(read_bool(dc)! == true);
	open_seq(dc)!;
	open_seq(dc)!;
	assert(read_bool(dc)! == false);
	close_seq(dc)!;
	close_seq(dc)!;
	close_seq(dc)!;
	finish(dc)!;

	let dc = &d(dat);
	open_seq(dc)!;
	assert(open_seq(dc) is invalid);

	let dc = &d(dat);
	open_seq(dc)!;
	assert(close_seq(dc) is badformat);

	let dat: [_]u8 = [
		0x30, 0x07, // seq
		0x0c, 0x05, 0x65, 0x66, 0x67, 0xc3, 0x96, // utf8 string
	];

	let dc = &d(dat);
	open_seq(dc)!;
	let r = strreader(dc, utag::UTF8_STRING)!;
	let s = io::drain(&r)!;
	defer free(s);
	assert(bytes::equal([0x65, 0x66, 0x67, 0xc3, 0x96], s));

	let dc = &d(dat);
	let buf: [4]u8 = [0...];
	open_seq(dc)!;
	let r = strreader(dc, utag::UTF8_STRING)!;
	assert(io::read(&r, buf)! == 3);
	assert(close_seq(dc) is badformat);

	// check unclosed
	let dc = &d(dat);
	open_seq(dc)!;
	assert(finish(dc) is invalid);

	let dc = &d(dat);
	open_seq(dc)!;
	let r = strreader(dc, utag::UTF8_STRING)!;
	let s = io::drain(&r)!;
	defer free(s);
	assert(finish(dc) is invalid);
};

@test fn invalid_seq() void = {
	let dat: [_]u8 = [
		0x30, 0x03, // seq containing data of size 3
		0x02, 0x03, 0x01, 0x02, 0x03, // int 0x010203 overflows seq
	];

	let dc = &d(dat);
	open_seq(dc)!;

	let buf: [3]u8 = [0...];
	assert(read_int(dc, buf) is invalid);
};

@test fn read_implicit() void = {
	let dat: [_]u8 = [
		0x30, 0x06, // seq
		0x85, 0x01, 0xff, // IMPLICIT bool true
		0x01, 0x01, 0x00, // bool false
	];

	let dc = &d(dat);
	open_seq(dc)!;
	expect_implicit(dc, class::CONTEXT, 5)!;
	assert(read_bool(dc)! == true);
	assert(read_u16(dc) is badformat);
};

@test fn read_bool() void = {
	assert(read_bool(&d([0x01, 0x01, 0xff]))!);
	assert(read_bool(&d([0x01, 0x01, 0x00]))! == false);
	assert(read_bool(&d([0x01, 0x02, 0x00, 0x00])) is invalid);
	// X.690, ch. 11.1
	assert(read_bool(&d([0x01, 0x01, 0x01])) is invalid);

	// invalid class
	assert(read_bool(&d([0x81, 0x01, 0x01])) is badformat);
	// must be primitive
	assert(read_bool(&d([0x21, 0x01, 0x01])) is invalid);
	// invalid tag
	assert(read_bool(&d([0x02, 0x01, 0x01])) is badformat);
};

@test fn read_null() void = {
	read_null(&d([0x05, 0x00]))!;
	read_null(&d([0x05, 0x01, 0x00])) is invalid;
	read_null(&d([0x85, 0x00])) is invalid;
	read_null(&d([0x01, 0x00])) is invalid;
};

@test fn read_int() void = {
	let buf: [8]u8 = [0...];

	assert(read_int(&d([0x02, 0x01, 0x01]), buf)! == 1);
	assert(buf[0] == 0x01);
	assert(read_int(&d([0x02, 0x01, 0x00]), buf)! == 1);
	assert(buf[0] == 0x00);
	assert(read_int(&d([0x02, 0x02, 0x01, 0x02]), buf)! == 2);
	assert(buf[0] == 0x01);
	assert(buf[1] == 0x02);

	// must have at least one byte
	assert(read_int(&d([0x02, 0x00]), buf) is invalid);
	// non minimal
	assert(read_int(&d([0x02, 0x02, 0x00, 0x01]), buf) is invalid);
	assert(read_int(&d([0x02, 0x02, 0xff, 0x81]), buf) is invalid);

	assert(read_u8(&d([0x02, 0x01, 0x00]))! == 0);
	assert(read_u8(&d([0x02, 0x01, 0x01]))! == 1);
	assert(read_u8(&d([0x02, 0x01, 0x7f]))! == 0x7f);
	assert(read_u8(&d([0x02, 0x01, 0x80])) is invalid);
	assert(read_u8(&d([0x02, 0x01, 0x81])) is invalid);
	assert(read_u8(&d([0x02, 0x02, 0x00, 0x80]))! == 0x80);
	assert(read_u8(&d([0x02, 0x02, 0x00, 0xff]))! == 0xff);

	assert(read_u16(&d([0x02, 0x01, 0x00]))! == 0);
	assert(read_u16(&d([0x02, 0x02, 0x0f, 0xff]))! == 0xfff);
	assert(read_u16(&d([0x02, 0x03, 0x00, 0xff, 0xff]))! == 0xffff);
	assert(read_u16(&d([0x02, 0x03, 0x01, 0xff, 0xff])) is invalid);
	assert(read_u32(&d([0x02, 0x03, 0x00, 0xff, 0xff]))! == 0xffff);

	let maxu64: [_]u8 = [
		0x02, 0x09, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
	];
	assert(read_u64(&d(maxu64))! == 0xffffffffffffffff);
	maxu64[2] = 0x01;
	assert(read_u64(&d(maxu64)) is invalid);
};

@test fn read_bitstr() void = {
	let buf: [8]u8 = [0...];
	let bs = read_bitstr(&d([0x03, 0x01, 0x00]), buf)!;
	assert(len(bs.0) == 0 && bs.1 == 0);
	assert(bitstr_isset(bs, 0)! == false);

	let bs = read_bitstr(&d([0x03, 0x02, 0x00, 0xff]), buf)!;
	assert(bytes::equal(bs.0, [0xff]) && bs.1 == 0);
	assert(bitstr_isset(bs, 0)!);
	assert(bitstr_isset(bs, 7)!);

	let bs = read_bitstr(&d([0x03, 0x03, 0x04, 0xab, 0xc0]), buf)!;
	assert(bytes::equal(bs.0, [0xab, 0xc0]) && bs.1 == 4);
	assert(bitstr_isset(bs, 0)!);
	assert(bitstr_isset(bs, 1)! == false);
	assert(bitstr_isset(bs, 8)!);
	assert(bitstr_isset(bs, 9)!);
	assert(!bitstr_isset(bs, 11)!);
	assert(bitstr_isset(bs, 12) is invalid);

	// unused bits must be zero
	assert(read_bitstr(&d([0x03, 0x03, 0x04, 0xab, 0xc1]), buf) is invalid);
	assert(read_bitstr(&d([0x03, 0x03, 0x07, 0xab, 0x40]), buf) is invalid);
};

let datbuf: [64]u8 = [0...];

fn newdatetime(s: str, tag: utag) []u8 = {
	let datetime = strings::toutf8(s);
	let datsz = len(datetime): u8;
	datbuf[..2] = [tag, datsz];
	datbuf[2..2 + datsz] = datetime;
	return datbuf[..2 + datsz];
};

@test fn read_utctime() void = {
	let derdatetime = newdatetime("231030133710Z", utag::UTC_TIME);
	let dt = read_utctime(&d(derdatetime), 2046)!;

	let fbuf: [24]u8 = [0...];
	assert(date::bsformat(fbuf, date::RFC3339, &dt)!
		== "2023-10-30T13:37:10+0000");

	let dt = read_utctime(&d(derdatetime), 2020)!;
	assert(date::bsformat(fbuf, date::RFC3339, &dt)!
		== "1923-10-30T13:37:10+0000");

	let derdatetime = newdatetime("2310301337100", utag::UTC_TIME);
	assert(read_utctime(&d(derdatetime), 2020) is error);

	let derdatetime = newdatetime("231030133710", utag::UTC_TIME);
	assert(read_utctime(&d(derdatetime), 2020) is error);

	let derdatetime = newdatetime("231030133a10Z", utag::UTC_TIME);
	assert(read_utctime(&d(derdatetime), 2020) is error);

	let derdatetime = newdatetime("231330133710Z", utag::UTC_TIME);
	assert(read_utctime(&d(derdatetime), 2020) is error);
};

@test fn read_gtime() void = {
	let derdatetime = newdatetime("20231030133710Z", utag::GENERALIZED_TIME);

	let dt = read_gtime(&d(derdatetime))!;

	let fbuf: [32]u8 = [0...];
	assert(date::bsformat(fbuf, date::RFC3339, &dt)!
		== "2023-10-30T13:37:10+0000");

	let derdatetime = newdatetime("20231030133710.1Z", utag::GENERALIZED_TIME);
	let dt = read_gtime(&d(derdatetime))!;
	assert(date::bsformat(fbuf, date::STAMPNANO, &dt)!
		== "2023-10-30 13:37:10.100000000");

	// must end with Z
	let derdatetime = newdatetime("20231030133710", utag::GENERALIZED_TIME);
	assert(read_gtime(&d(derdatetime)) is error);
	let derdatetime = newdatetime("202310301337100", utag::GENERALIZED_TIME);
	assert(read_gtime(&d(derdatetime)) is error);

	// seconds must always be present
	let derdatetime = newdatetime("202310301337", utag::GENERALIZED_TIME);
	assert(read_gtime(&d(derdatetime)) is error);
	let derdatetime = newdatetime("202310301337Z", utag::GENERALIZED_TIME);
	assert(read_gtime(&d(derdatetime)) is error);

	// fractional seconds must not end with 0. must be ommitted if 0
	let derdatetime = newdatetime("20231030133710.", utag::GENERALIZED_TIME);
	assert(read_gtime(&d(derdatetime)) is error);

	let derdatetime = newdatetime("20231030133710.Z", utag::GENERALIZED_TIME);
	assert(read_gtime(&d(derdatetime)) is error);

	let derdatetime = newdatetime("20231030133710.0", utag::GENERALIZED_TIME);
	assert(read_gtime(&d(derdatetime)) is error);

	let derdatetime = newdatetime("20231030133710.0Z", utag::GENERALIZED_TIME);
	assert(read_gtime(&d(derdatetime)) is error);

	let derdatetime = newdatetime("20231030133710.10Z", utag::GENERALIZED_TIME);
	assert(read_gtime(&d(derdatetime)) is error);

	// TODO midnight is YYYYMMDD000000Z
};

@test fn read_oid() void = {
	let db = oiddb {
		lut = [0x03, 0x2b, 0x65, 0x70, 0x03, 0x55, 0x04, 0x03],
		index = [0, 4],
		names = ["ed25519", "id-at-commonName"],
	};

	assert(read_oid(&d([0x06, 0x03, 0x55, 0x04, 0x03]), &db)! == 1);
	assert(stroid(&db, 1) == "id-at-commonName");

	assert(bytes::equal([0x55, 0x04, 0x03],
			read_rawoid(&d([0x06, 0x03, 0x55, 0x04, 0x03]))!));
};
