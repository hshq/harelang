// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use io;
use memio;


// Data types specified in the standard
export type class = enum u8 {
	UNIVERSAL = 0x0,
	APPLICATION = 0x1,
	CONTEXT = 0x2,
	PRIVATE = 0x3,
};

// String representation of 'c'.
export fn strclass(c: class) str = {
	switch (c) {
	case class::UNIVERSAL =>
		return "UNIVERSAL";
	case class::APPLICATION =>
		return "APPLICATION";
	case class::CONTEXT =>
		return "CONTEXT_SPECIFIC";
	case class::PRIVATE =>
		return "PRIVATE";
	};
};

// Universal tags as defined in x.690. Not all are supported by this
// implemenation.
export type utag = enum u8 {
	RESERVED = 0x00,
	BOOLEAN = 0x01,
	INTEGER = 0x02,
	BITSTRING = 0x03,
	OCTET_STRING = 0x04,
	NULL = 0x05,
	OID = 0x06,
	OBJECT_DESCRIPTOR = 0x07,
	EXTERNAL = 0x08,
	REAL = 0x09,
	ENUMERATED = 0x0a,
	EMBEDDED_PDV = 0x0b,
	UTF8_STRING = 0x0c,
	RELATIVE_OID = 0x0d,
	TIME = 0x0e,
	RESERVED2 = 0x0f,
	SEQUENCE = 0x10,
	SET = 0x11,
	NUMERIC_STRING = 0x12,
	PRINTABLE_STRING = 0x13,
	TELETEX_STRING = 0x14, // T61String
	VIDEOTEX_STRING = 0x15,
	IA5_STRING = 0x16,
	UTC_TIME = 0x17,
	GENERALIZED_TIME = 0x18,
	GRAPHIC_STRING = 0x19,
	VISIBLE_STRING = 0x1a, // iso646String
	GENERAL_STRING = 0x1b,
	UNIVERSAL_STRING = 0x1c,
	UNKNOWN = 0x1d,
	BMP_STRING = 0x1e,
	DATE = 0x1f,
	TIME_OF_DAY = 0x20,
	DATE_TIME = 0x21,
	DURATION = 0x22,
	OID_IRI = 0x23,
	OID_RELATIVE_IRI = 0x24,
};

// String representation of universal tag ids. May return a statically allocated
// string and will be overwritten on the next call.
export fn strtag(dh: head) str = {
	static let tagstrbuf: [128]u8 = [0...];

	if (dh.class != class::UNIVERSAL) {
		let tagstr = memio::fixed(tagstrbuf);

		fmt::fprint(&tagstr, "[")!;
		if (dh.class != class::CONTEXT) {
			fmt::fprintf(&tagstr, "{} ", strclass(dh.class))!;
		};
		fmt::fprintf(&tagstr, "{:x}]", dh.tagid)!;
		return memio::string(&tagstr)!;
	};

	if (dh.tagid >> 8 != 0) {
		return "UNKNOWN";
	};

	switch (dh.tagid: u8) {
	case utag::BOOLEAN =>
		return "BOOLEAN";
	case utag::INTEGER =>
		return "INTEGER";
	case utag::BITSTRING =>
		return "BITSTRING";
	case utag::OCTET_STRING =>
		return "OCTET_STRING";
	case utag::NULL =>
		return "NULL";
	case utag::OID =>
		return "OBJECT_IDENTIFIER";
	case utag::OBJECT_DESCRIPTOR =>
		return "OBJECT_DESCRIPTOR";
	case utag::EXTERNAL =>
		return "EXTERNAL";
	case utag::REAL =>
		return "REAL";
	case utag::ENUMERATED =>
		return "ENUMERATED";
	case utag::EMBEDDED_PDV =>
		return "EMBEDDED_PDV";
	case utag::UTF8_STRING =>
		return "UTF8_STRING";
	case utag::RELATIVE_OID =>
		return "RELATIVE_OID";
	case utag::TIME =>
		return "TIME";
	case utag::SEQUENCE =>
		return "SEQUENCE";
	case utag::SET =>
		return "SET";
	case utag::PRINTABLE_STRING =>
		return "PRINTABLE_STRING";
	case utag::TELETEX_STRING =>
		return "TELETEX_STRING";
	case utag::UTC_TIME =>
		return "UTC_TIME";
	case =>
		return "UNKNOWN";
	};
};
