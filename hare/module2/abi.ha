use ascii;
use bufio;
use crypto::sha256;
use fmt;
use hare::ast;
use hare::lex;
use hare::parse;
use hare::unparse;
use hash;
use io;
use os;
use sort;

// Scans from an I/O handle, adding any dependencies to the module depends, and
// updating the module ABI hash.
fn scanabi(state: *scan_state, path: str, in: io::handle) (void | error) = {
	let rbuf: [os::BUFSIZ]u8 = [0...];
	let bufin = bufio::buffered(in, rbuf, []);

	// XXX: This function allocates a memory to store a complete AST, which
	// would probably not be necessary if we had a better parser design.
	let mod = &state.mod;
	let lexer = lex::init(&bufin, path);
	let unit = parse::subunit(&lexer)?;
	defer ast::subunit_free(unit);

	for (let i = 0z; i < len(unit.imports); i += 1) {
		if (!havedep(&mod.depends, unit.imports[i].ident)) {
			let id = ast::ident_dup(unit.imports[i].ident);
			append(mod.depends, dependency {
				ident = id,
				...
			});
		};
	};

	// Sort them so that re-arranging the file does not change the ABI hash.
	// XXX: This could technically be better still: we could accumulate all
	// declarations for the whole unit (including all subunits) and then the
	// hash would not change if you move declarations from one file to
	// another without changing their type -- but the worst case scenario is
	// a cache break and we can live with that for now.
	sort::sort(unit.decls, size(ast::decl), &decl_cmp);

	for (let i = 0z; i < len(unit.decls); i += 1) {
		const decl = &unit.decls[i];
		if (!decl.exported) {
			continue;
		};

		match (decl.decl) {
		case let dconst: []ast::decl_const =>
			for (let j = 0z; j < len(dconst); j += 1) {
				scan_decl_const(state, &dconst[j]);
			};
		case let dglobal: []ast::decl_global =>
			for (let j = 0z; j < len(dglobal); j += 1) {
				scan_decl_global(state, &dglobal[j]);
			};
		case let dtype: []ast::decl_type =>
			for (let j = 0z; j < len(dtype); j += 1) {
				scan_decl_type(state, &dtype[j]);
			};
		case let dfunc: ast::decl_func =>
			scan_decl_func(state, &dfunc);
		};
	};
};

fn havedep(sl: *[]dependency, id: ast::ident) bool = {
	for (let i = 0z; i < len(sl); i += 1) {
		if (ast::ident_eq(sl[i].ident, id)) {
			return true;
		};
	};
	return false;
};

fn scan_decl_const(state: *scan_state, dconst: *ast::decl_const) void = {
	fmt::fprintf(&state.abi, "const\0")!;
	unparse::ident(&state.abi, dconst.ident)!;
	unparse::_type(&state.abi, 0, dconst._type)!;
	unparse::expr(&state.abi, 0, *dconst.init)!;
};

fn scan_decl_global(state: *scan_state, dglobal: *ast::decl_global) void = {
	fmt::fprintf(&state.abi, "global\0")!;
	unparse::ident(&state.abi, dglobal.ident)!;
	fmt::fprintf(&state.abi, "{}\0{}\0", dglobal.is_const, dglobal.symbol)!;
	unparse::_type(&state.abi, 0, dglobal._type)!;
};

fn scan_decl_type(state: *scan_state, dtype: *ast::decl_type) void = {
	fmt::fprintf(&state.abi, "type\0")!;
	unparse::ident(&state.abi, dtype.ident)!;
	unparse::_type(&state.abi, 0, dtype._type)!;
};

fn scan_decl_func(state: *scan_state, dfunc: *ast::decl_func) void = {
	fmt::fprintf(&state.abi, "func\0")!;
	unparse::ident(&state.abi, dfunc.ident)!;
	fmt::fprintf(&state.abi, "{}\0{}\0", dfunc.symbol, dfunc.attrs: int)!;
	unparse::_type(&state.abi, 0, dfunc.prototype)!;
};

fn decl_cmp(a: const *void, b: const *void) int = {
	const a = a: const *ast::decl;
	const b = b: const *ast::decl;
	const id_a = decl_ident(a), id_b = decl_ident(b);
	return ascii::strcmp(id_a[len(id_a) - 1], id_b[len(id_b) - 1]) as int;
};

fn decl_ident(decl: *ast::decl) ast::ident = {
	// XXX: This is also less than ideal for declarations with multiple
	// objects
	match (decl.decl) {
	case let f: ast::decl_func =>
		return f.ident;
	case let t: []ast::decl_type =>
		assert(len(t) == 1);
		return t[0].ident;
	case let c: []ast::decl_const =>
		assert(len(c) == 1);
		return c[0].ident;
	case let g: []ast::decl_global =>
		assert(len(g) == 1);
		return g[0].ident;
	};
};
