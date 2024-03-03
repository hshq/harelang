// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use errors;
use fmt;
use io;
use math::{divu};
use memio;
use strings;


// An oid database that contains a lookup table of known oids in the DER format.
// A database of oids required by the standard library can be found in
// [[encoding::asn1::stdoid]].
//
// The database can be used with [[oid_from_der]] and [[oid_to_der]] to convert
// an oid between integer and DER encoding. [[read_oid]] and [[write_oid]] can
// be used to decode or encode the oid directly from and to DER.
//
// If the standard oid database is missing entries for the given use case, an
// individual database can be generated using the genoiddb command found in
// cmd/. Take a look at encoding/asn1/stdoid/db.txt for an example database
// file.
export type oiddb = struct {
	lut: []u8,
	index: []size,
	names: []str,
};

// Numeric id of an oid which is unique within an [[oiddb]].
export type oid = u32;

// Reads an oid if present in 'db'. Returns [[badformat]] if the oid is unknown.
export fn read_oid(d: *decoder, db: *oiddb) (oid | error) = {
	let raw = read_rawoid(d)?;

	match (oid_from_der(db, raw)) {
	case let o: oid =>
		return o;
	case =>
		return badformat;
	};
};

// Reads any [[oid]] and returns the DER encoded form. The returned value is
// borrowed from a static buffer.
export fn read_rawoid(d: *decoder) ([]u8 | error) = {
	def OIDBUFSZ: size = 64; // estimated
	static let oidbuf: [OIDBUFSZ]u8 = [0...];

	const dh = next(d)?;
	expect_utag(dh, utag::OID)?;
	if (dsz(dh) < 2) {
		return invalid;
	};
	const n = read_bytes(d, oidbuf)?;
	return oidbuf[..n];
};

// Writes given [[oid]] from the [[oiddb]] 'db'.
export fn write_oid(e: *encoder, db: *oiddb, oid: oid) (void | overflow) = {
	let doid = oid_to_der(db, oid);
	write_fixedprim(e, class::UNIVERSAL, utag::OID, doid)?;
};

// Looks up DER encoded oid 'raw' in 'db' and returns an [[oid]] if found, or
// void otheriwse.
export fn oid_from_der(db: *oiddb, raw: []u8) (void | oid) = {
	for (let i = 0z; i < len(db.index); i += 1) {
		const off = db.index[i];
		const l = db.lut[off];
		if (bytes::equal(raw, db.lut[off + 1..off + 1 + l])) {
			return i: oid;
		};
	};
};

// Borrows the DER representation of a known oid from 'db'.
export fn oid_to_der(db: *oiddb, o: oid) []u8 = {
	const off = db.index[o];
	const l = db.lut[off];
	return db.lut[off + 1..off + 1 + l];
};

// Looks up a str representation of an oid from the database.
export fn stroid(db: *oiddb, o: oid) str = {
	return db.names[o];
};

// Returns the dot id as string. The caller must free returned value. This
// function may fail if the oid overflows the internal buffer, or an invalid
// value is provided.
export fn strrawoid(der: []u8) (str | io::error) = {
	let s = memio::dynamic();
	let ok = false;
	defer if (!ok) io::close(&s)!;

	if (len(der) < 1) {
		return errors::invalid;
	};

	const (a, b) = divu(0, der[0], 40);
	fmt::fprintf(&s, "{}.{}", a, b)?;

	let j = 2z;
	let el = 0u32;
	let bits: int = size(u32): int * 8;

	for (let i = 1z; i < len(der); i += 1) {
		el += der[i] & 0x7f;

		if (der[i] & 0x80 != 0) {
			if (bits - 7 < 0) {
				return errors::overflow;
			};
			el <<= 7;
			bits -= 7;
		} else {
			fmt::fprintf(&s, ".{}", el)?;
			el = 0;
			j += 1;
			bits = size(u32): int * 8;
		};
	};

	ok = true;
	return memio::string(&s)!;
};

@test fn strrawoid() void = {
	let der: [_]u8 = [0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01];
	let s = strrawoid(der)!;
	defer free(s);
	assert(s == "1.2.840.113549.1.1.1");
};
