use fmt;
use hare::types;
use hare::types::{builtin};

type stype = enum {
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
) const *qtype = match (_type.repr) {
	bi: builtin => switch (bi) {
		builtin::CHAR =>
			if (extype) &qbyte else &qword,
		builtin::I8, builtin::U8 =>
			if (extype) &qbyte else &qword,
		builtin::I16, builtin::U16 =>
			if (extype) &qhalf else &qword,
		builtin::BOOL => &qword,
		builtin::F32 => &qsingle,
		builtin::F64 => &qdouble,
		builtin::I32, builtin::U32, builtin::RUNE => &qword,
		builtin::I64, builtin::U64 => &qlong,
		builtin::INT, builtin::UINT,
		builtin::NULL, builtin::UINTPTR,
		builtin::SIZE => switch (_type.sz) {
			4 => &qword,
			8 => &qlong,
			* => abort(),
		},
		builtin::STR => qtype_aggregate(ctx, _type),
		builtin::VOID => abort(),
	},
	* => abort(),
};

fn qtype_aggregate(ctx: *context, _type: const *types::_type) const *qtype = {
	abort(); // TODO
};

// XXX: This dereference should not be necessary after the match
// overhaul
fn qtype_repr(qtype: const *qtype) const str = match (*qtype) {
	st: stype => {
		static let buf: [1]u8 = [0...];
		yield fmt::bsprintf(buf, "{}", st: rune);
	},
	qc: qcompound => abort(), // TODO
	void => "",
};
