// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::types;
use hare::types::{builtin};

type stype = enum rune {
	BYTE = 'b',
	HALF = 'h',
	WORD = 'w',
	LONG = 'l',
	SINGLE = 's',
	DOUBLE = 'd',
};

type qcompound = struct {
	name: str,
	fields: []qtype_field,
	base: const *types::_type,
};

type qtype = (stype | qcompound | void);

type qtype_field = struct {
	qtype: const *qtype,
	count: size,
};

// Singletons
const qbyte: qtype = stype::BYTE;
const qhalf: qtype = stype::HALF;
const qword: qtype = stype::WORD;
const qlong: qtype = stype::LONG;
const qsingle: qtype = stype::SINGLE;
const qdouble: qtype = stype::DOUBLE;

fn qtype_lookup(
	ctx: *context,
	_type: const *types::_type,
	extype: bool,
) const *qtype = {
	match (_type.repr) {
	case let bi: builtin =>
		switch (bi) {
		case builtin::I8, builtin::U8 =>
			return if (extype) &qbyte else &qword;
		case builtin::I16, builtin::U16 =>
			return if (extype) &qhalf else &qword;
		case builtin::BOOL =>
			return &qword;
		case builtin::F32 =>
			return &qsingle;
		case builtin::F64 =>
			return &qdouble;
		case builtin::I32, builtin::U32, builtin::RUNE =>
			return &qword;
		case builtin::I64, builtin::U64 =>
			return &qlong;
		case builtin::INT, builtin::UINT, builtin::NULL,
			builtin::UINTPTR, builtin::SIZE =>
			switch (_type.sz) {
			case 4 =>
				return &qword;
			case 8 =>
				return &qlong;
			case => abort();
			};
		case builtin::STR =>
			return qtype_aggregate(ctx, _type);
		case builtin::VOID => abort();
		case => abort(); // TODO
		};
	case => abort();
	};
};

fn qtype_aggregate(ctx: *context, _type: const *types::_type) const *qtype = {
	abort(); // TODO
};

fn qtype_repr(qtype: const *qtype) const str = {
	// XXX: This dereference should not be necessary after the match
	// overhaul
	match (*qtype) {
	case let st: stype =>
		static let buf: [1]u8 = [0...];
		return fmt::bsprintf(buf, "{}", st: rune);
	case let qc: qcompound => abort(); // TODO
	case void =>
		return "";
	};
};
