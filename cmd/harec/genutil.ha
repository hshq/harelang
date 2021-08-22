use fmt;

fn emit(
	ctx: *context,
	out: (value | void),
	instr: qinstr,
	args: value...
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
		abort(); // TODO
	};
	fmt::fprintln(ctx.out)!;
};

fn mklabel(ctx: *context, name: str) str = {
	static let buf: [1024]u8 = [0...];
	let serial = ctx.serial;
	ctx.serial += 1;
	return fmt::bsprintf(buf, "@{}.{}", name, serial);
};
