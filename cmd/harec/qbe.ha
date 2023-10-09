// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fmt;
use hare::types;
use hare::types::{builtin};
use io;

type global = str;
type temporary = str;
type label = str;
type qvoid = void;
type constant = (u32 | u64 | f32 | f64 | str | qvoid);
type qval = (global | temporary | label | constant);
type qtypeval = (const *qtype, qval);

type value = struct {
	value: qval,
	_type: const *types::_type,
};

const vvoid: value = value {
	value = qvoid,
	_type = &types::builtin_void,
};

fn emit(
	to: io::handle,
	out: (qtypeval | void),
	instr: qinstr,
	args: (value | qval | qtype)...
) void = {
	fmt::fprintf(to, "\t")!;
	match (out) {
	case let val: qtypeval =>
		const ty = val.0, val = val.1;
		qval_emit(to, val);
		fmt::fprintf(to, " ={} ", qtype_repr(ty))!;
	case void => void;
	};
	// TODO: The langauge should provide a means of converting enums to
	// strings without this
	fmt::fprint(to, switch (instr) {
	case qinstr::ADD =>
		yield "add";
	case qinstr::ALLOC16 =>
		yield "alloc16";
	case qinstr::ALLOC4 =>
		yield "alloc4";
	case qinstr::ALLOC8 =>
		yield "alloc8";
	case qinstr::AND =>
		yield "and";
	case qinstr::CALL =>
		yield "call";
	case qinstr::CAST =>
		yield "cast";
	case qinstr::CEQD =>
		yield "ceqd";
	case qinstr::CEQL =>
		yield "ceql";
	case qinstr::CEQS =>
		yield "ceqs";
	case qinstr::CEQW =>
		yield "ceqw";
	case qinstr::CGED =>
		yield "cged";
	case qinstr::CGES =>
		yield "cges";
	case qinstr::CGTD =>
		yield "cgtd";
	case qinstr::CGTS =>
		yield "cgts";
	case qinstr::CLED =>
		yield "cled";
	case qinstr::CLES =>
		yield "cles";
	case qinstr::CLTD =>
		yield "cltd";
	case qinstr::CLTS =>
		yield "clts";
	case qinstr::CNED =>
		yield "cned";
	case qinstr::CNEL =>
		yield "cnel";
	case qinstr::CNES =>
		yield "cnes";
	case qinstr::CNEW =>
		yield "cnew";
	case qinstr::COD =>
		yield "cod";
	case qinstr::COPY =>
		yield "copy";
	case qinstr::COS =>
		yield "cos";
	case qinstr::CSGEL =>
		yield "csgel";
	case qinstr::CSGEW =>
		yield "csgew";
	case qinstr::CSGTL =>
		yield "csgtl";
	case qinstr::CSGTW =>
		yield "csgtw";
	case qinstr::CSLEL =>
		yield "cslel";
	case qinstr::CSLEW =>
		yield "cslew";
	case qinstr::CSLTL =>
		yield "csltl";
	case qinstr::CSLTW =>
		yield "csltw";
	case qinstr::CUGEL =>
		yield "cugel";
	case qinstr::CUGEW =>
		yield "cugew";
	case qinstr::CUGTL =>
		yield "cugtl";
	case qinstr::CUGTW =>
		yield "cugtw";
	case qinstr::CULEL =>
		yield "culel";
	case qinstr::CULEW =>
		yield "culew";
	case qinstr::CULTL =>
		yield "cultl";
	case qinstr::CULTW =>
		yield "cultw";
	case qinstr::CUOD =>
		yield "cuod";
	case qinstr::CUOS =>
		yield "cuos";
	case qinstr::DIV =>
		yield "div";
	case qinstr::DTOSI =>
		yield "dtosi";
	case qinstr::EXTS =>
		yield "exts";
	case qinstr::EXTSB =>
		yield "extsb";
	case qinstr::EXTSH =>
		yield "extsh";
	case qinstr::EXTSW =>
		yield "extsw";
	case qinstr::EXTUB =>
		yield "extub";
	case qinstr::EXTUH =>
		yield "extuh";
	case qinstr::EXTUW =>
		yield "extuw";
	case qinstr::JMP =>
		yield "jmp";
	case qinstr::JNZ =>
		yield "jnz";
	case qinstr::LOADD =>
		yield "loadd";
	case qinstr::LOADL =>
		yield "loadl";
	case qinstr::LOADS =>
		yield "loads";
	case qinstr::LOADSB =>
		yield "loadsb";
	case qinstr::LOADSH =>
		yield "loadsh";
	case qinstr::LOADSW =>
		yield "loadsw";
	case qinstr::LOADUB =>
		yield "loadub";
	case qinstr::LOADUH =>
		yield "loaduh";
	case qinstr::LOADUW =>
		yield "loaduw";
	case qinstr::MUL =>
		yield "mul";
	case qinstr::OR =>
		yield "or";
	case qinstr::REM =>
		yield "rem";
	case qinstr::RET =>
		yield "ret";
	case qinstr::SAR =>
		yield "sar";
	case qinstr::SHL =>
		yield "shl";
	case qinstr::SHR =>
		yield "shr";
	case qinstr::SLTOF =>
		yield "sltof";
	case qinstr::STOREB =>
		yield "storeb";
	case qinstr::STORED =>
		yield "stored";
	case qinstr::STOREH =>
		yield "storeh";
	case qinstr::STOREL =>
		yield "storel";
	case qinstr::STORES =>
		yield "stores";
	case qinstr::STOREW =>
		yield "storew";
	case qinstr::STOSI =>
		yield "stosi";
	case qinstr::SUB =>
		yield "sub";
	case qinstr::SWTOF =>
		yield "swtof";
	case qinstr::TRUNCD =>
		yield "truncd";
	case qinstr::UDIV =>
		yield "udiv";
	case qinstr::UREM =>
		yield "urem";
	case qinstr::XOR =>
		yield "xor";
	})!;
	for (let i = 0z; i < len(args); i += 1) {
		const arg = match (args[i]) {
		case let v: value =>
			yield v.value;
		case =>
			yield args[i];
		};
		match (arg) {
		case let v: value => abort(); // Invariant
		case let qv: qval =>
			yield qval_emit(to, qv);
		case let qt: qtype =>
			abort(); // TODO
		};
		if (i + 1 < len(args)) {
			fmt::fprint(to, ",")!;
		};
	};
	fmt::fprintln(to)!;
};

fn qval_emit(to: io::handle, qv: qval) void = {
	match (qv) {
	case let g: global =>
		fmt::fprintf(to, " ${}", g)!;
	case let t: temporary =>
		fmt::fprintf(to, " %{}", t)!;
	case let l: label =>
		fmt::fprintf(to, " @{}", l)!;
	case let c: constant =>
		match (c) {
		case qvoid => abort();
		case let v: (u32 | u64 | f32 | f64 | str) =>
			fmt::fprintf(to, " {}", v)!;
		};
	};
};

fn qinstr_alloc(ty: *types::_type) qinstr = {
	switch (ty._align) {
	case 4 =>
		return qinstr::ALLOC4;
	case 8 =>
		return qinstr::ALLOC8;
	case 16 =>
		return qinstr::ALLOC16;
	case => abort();
	};
};

fn qinstr_store(
	ctx: *context,
	ty: *types::_type,
) qinstr = {
	match (ty.repr) {
	case let al: types::alias =>
		return qinstr_store(ctx, al.secondary: *types::_type);
	case let bi: types::builtin =>
		switch (bi) {
		case builtin::STR, builtin::VOID => abort();
		case builtin::F32 =>
			return qinstr::STORES;
		case builtin::F64 =>
			return qinstr::STORED;
		case =>
			switch (ty.sz) {
			case 1 =>
				return qinstr::STOREB;
			case 2 =>
				return qinstr::STOREH;
			case 4 =>
				return qinstr::STOREW;
			case 8 =>
				return qinstr::STOREL;
			case => abort();
			};
		};
	case types::pointer =>
		if (ctx.arch.ptr == &qlong) {
			return qinstr::STOREL;
		} else if (ctx.arch.ptr == &qword) {
			return qinstr::STOREW;
		} else abort();
	case let en: types::_enum => abort(); // TODO
	case => abort();
	};
};

fn qinstr_load(
	ctx: *context,
	ty: *types::_type,
) qinstr = {
	match (ty.repr) {
	case let al: types::alias =>
		return qinstr_load(ctx, al.secondary: *types::_type);
	case let bi: types::builtin =>
		switch (bi) {
		case builtin::STR, builtin::VOID => abort();
		case builtin::F32 =>
			return qinstr::LOADS;
		case builtin::F64 =>
			return qinstr::LOADD;
		case =>
			switch (ty.sz) {
			case 1 =>
				if (types::is_signed(ty)) {
					return qinstr::LOADSB;
				} else {
					return qinstr::LOADUB;
				};
			case 2 =>
				if (types::is_signed(ty)) {
					return qinstr::LOADSH;
				} else {
					return qinstr::LOADUH;
				};
			case 4 =>
				if (types::is_signed(ty)) {
					return qinstr::LOADSW;
				} else {
					return qinstr::LOADUW;
				};
			case 8 =>
				return qinstr::LOADL;
			case => abort();
			};
		};
	case types::pointer =>
		if (ctx.arch.ptr == &qlong) {
			return qinstr::LOADL;
		} else if (ctx.arch.ptr == &qword) {
			return qinstr::LOADUW;
		} else abort();
	case let en: types::_enum => abort(); // TODO
	case => abort();
	};
};

type qinstr = enum {
	ADD,
	ALLOC16,
	ALLOC4,
	ALLOC8,
	AND,
	CALL,
	CAST,
	CEQD,
	CEQL,
	CEQS,
	CEQW,
	CGED,
	CGES,
	CGTD,
	CGTS,
	CLED,
	CLES,
	CLTD,
	CLTS,
	CNED,
	CNEL,
	CNES,
	CNEW,
	COD,
	COPY,
	COS,
	CSGEL,
	CSGEW,
	CSGTL,
	CSGTW,
	CSLEL,
	CSLEW,
	CSLTL,
	CSLTW,
	CUGEL,
	CUGEW,
	CUGTL,
	CUGTW,
	CULEL,
	CULEW,
	CULTL,
	CULTW,
	CUOD,
	CUOS,
	DIV,
	DTOSI,
	EXTS,
	EXTSB,
	EXTSH,
	EXTSW,
	EXTUB,
	EXTUH,
	EXTUW,
	JMP,
	JNZ,
	LOADD,
	LOADL,
	LOADS,
	LOADSB,
	LOADSH,
	LOADSW,
	LOADUB,
	LOADUH,
	LOADUW,
	MUL,
	OR,
	REM,
	RET,
	SAR,
	SHL,
	SHR,
	SLTOF,
	STOREB,
	STORED,
	STOREH,
	STOREL,
	STORES,
	STOREW,
	STOSI,
	SUB,
	SWTOF,
	TRUNCD,
	UDIV,
	UREM,
	XOR,
};
