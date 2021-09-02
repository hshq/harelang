use fmt;
use hare::types;

type global = str;
type temporary = str;
type label = str;
type qvoid = void;
type constant = (u32 | u64 | f32 | f64 | str | qvoid);
type qval = (global | temporary | label | constant);

type value = struct {
	value: qval,
	_type: const *types::_type,
};

const vvoid: value = value {
	value = qvoid,
	_type = &types::builtin_void,
};

fn emit(
	ctx: *context,
	out: (value | void),
	instr: qinstr,
	args: (value | qval | qtype)...
) void = {
	fmt::fprintf(ctx.out, "\t")!;
	match (out) {
		val: value => abort(), // TODO
		void => void,
	};
	// TODO: The langauge should provide a means of converting enums to
	// strings without this
	fmt::fprint(ctx.out, switch (instr) {
		qinstr::ADD => "add",
		qinstr::ALLOC16 => "alloc16",
		qinstr::ALLOC4 => "alloc4",
		qinstr::ALLOC8 => "alloc8",
		qinstr::AND => "and",
		qinstr::CALL => "call",
		qinstr::CAST => "cast",
		qinstr::CEQD => "ceqd",
		qinstr::CEQL => "ceql",
		qinstr::CEQS => "ceqs",
		qinstr::CEQW => "ceqw",
		qinstr::CGED => "cged",
		qinstr::CGES => "cges",
		qinstr::CGTD => "cgtd",
		qinstr::CGTS => "cgts",
		qinstr::CLED => "cled",
		qinstr::CLES => "cles",
		qinstr::CLTD => "cltd",
		qinstr::CLTS => "clts",
		qinstr::CNED => "cned",
		qinstr::CNEL => "cnel",
		qinstr::CNES => "cnes",
		qinstr::CNEW => "cnew",
		qinstr::COD => "cod",
		qinstr::COPY => "copy",
		qinstr::COS => "cos",
		qinstr::CSGEL => "csgel",
		qinstr::CSGEW => "csgew",
		qinstr::CSGTL => "csgtl",
		qinstr::CSGTW => "csgtw",
		qinstr::CSLEL => "cslel",
		qinstr::CSLEW => "cslew",
		qinstr::CSLTL => "csltl",
		qinstr::CSLTW => "csltw",
		qinstr::CUGEL => "cugel",
		qinstr::CUGEW => "cugew",
		qinstr::CUGTL => "cugtl",
		qinstr::CUGTW => "cugtw",
		qinstr::CULEL => "culel",
		qinstr::CULEW => "culew",
		qinstr::CULTL => "cultl",
		qinstr::CULTW => "cultw",
		qinstr::CUOD => "cuod",
		qinstr::CUOS => "cuos",
		qinstr::DIV => "div",
		qinstr::DTOSI => "dtosi",
		qinstr::EXTS => "exts",
		qinstr::EXTSB => "extsb",
		qinstr::EXTSH => "extsh",
		qinstr::EXTSW => "extsw",
		qinstr::EXTUB => "extub",
		qinstr::EXTUH => "extuh",
		qinstr::EXTUW => "extuw",
		qinstr::JMP => "jmp",
		qinstr::JNZ => "jnz",
		qinstr::LOADD => "loadd",
		qinstr::LOADL => "loadl",
		qinstr::LOADS => "loads",
		qinstr::LOADSB => "loadsb",
		qinstr::LOADSH => "loadsh",
		qinstr::LOADSW => "loadsw",
		qinstr::LOADUB => "loadub",
		qinstr::LOADUH => "loaduh",
		qinstr::LOADUW => "loaduw",
		qinstr::MUL => "mul",
		qinstr::OR => "or",
		qinstr::REM => "rem",
		qinstr::RET => "ret",
		qinstr::SAR => "sar",
		qinstr::SHL => "shl",
		qinstr::SHR => "shr",
		qinstr::SLTOF => "sltof",
		qinstr::STOREB => "storeb",
		qinstr::STORED => "stored",
		qinstr::STOREH => "storeh",
		qinstr::STOREL => "storel",
		qinstr::STORES => "stores",
		qinstr::STOREW => "storew",
		qinstr::STOSI => "stosi",
		qinstr::SUB => "sub",
		qinstr::SWTOF => "swtof",
		qinstr::TRUNCD => "truncd",
		qinstr::UDIV => "udiv",
		qinstr::UREM => "urem",
		qinstr::XOR => "xor",
	})!;
	for (let i = 0z; i < len(args); i += 1) {
		const arg = match (args[i]) {
			v: value => v.value,
			* => args[i],
		};
		match (arg) {
			v: value => abort(), // Invariant
			qv: qval => match (qv) {
				g: global => fmt::fprintf(ctx.out, " ${}", g)!,
				t: temporary => fmt::fprintf(ctx.out, " %{}", t)!,
				l: label => fmt::fprintf(ctx.out, " @{}", l)!,
				c: constant => match (c) {
					qvoid => abort(),
					v: (u32 | u64 | f32 | f64 | str) =>
						fmt::fprintf(ctx.out, " {}", v)!,
				},
			},
			qt: qtype => abort(), // TODO
		};
		if (i + 1 < len(args)) {
			fmt::fprint(ctx.out, ",")!;
		};
	};
	fmt::fprintln(ctx.out)!;
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
