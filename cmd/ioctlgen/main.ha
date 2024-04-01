// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::lex::{ltok};
use hare::parse;
use hare::types;
use io;
use memio;
use os;
use regex;
use strings;

let ioctlre: regex::regex = regex::regex { ... };
let typedefre: regex::regex = regex::regex { ... };

@init fn init() void = {
	ioctlre = regex::compile(`@(_IO[RW]*)\((.*)\)`)!;
	typedefre = regex::compile(`^(export )?type `)!;
};

@fini fn fini() void = {
	regex::finish(&ioctlre);
	regex::finish(&typedefre);
};

type dir = enum u32 {
	IO = 0,
	IOW = 1,
	IOR = 2,
	IOWR = IOW | IOR,
};

type ioctl = (dir, rune, u32, const nullable *types::_type);

export fn main() void = {
	// TODO: Configurable arch
	const store = types::store(types::x86_64, null, null);
	defer types::store_free(store);

	for (true) {
		const line = match (bufio::read_line(os::stdin)!) {
		case io::EOF =>
			break;
		case let line: []u8 =>
			yield strings::fromutf8(line)!;
		};
		defer free(line);

		if (regex::test(&typedefre, line)) {
			bufio::unreadrune(os::stdin, '\n');
			bufio::unread(os::stdin, strings::toutf8(line));
			loadtype(store);
			continue;
		};

		let groups = regex::find(&ioctlre, line);
		defer free(groups);
		if (len(groups) == 0) {
			fmt::println(line)!;
			continue;
		};

		const dir = switch (groups[1].content) {
		case "_IO" =>
			yield dir::IO;
		case "_IOR" =>
			yield dir::IOR;
		case "_IOW" =>
			yield dir::IOW;
		case "_IOWR" =>
			yield dir::IOWR;
		case =>
			fmt::fatalf("Unknown ioctl direction {}",
				groups[1].content);
		};
		const ioctl = parseioctl(store, dir, groups[2].content);

		const prefix = strings::sub(line, 0, groups[1].start - 1);
		fmt::printfln("{}0x{:x};", prefix, ioctlno(&ioctl))!;
	};
};

fn loadtype(store: *types::typestore) void = {
	let tee = io::tee(os::stdin, os::stdout);
	let sc = bufio::newscanner(&tee);
	defer bufio::finish(&sc);
	let lex = lex::init(&sc, "<ioctl>");
	const decl = match (parse::decl(&lex)) {
	case let err: parse::error =>
		fmt::fatal("Error parsing type declaration:",
			parse::strerror(err));
	case let decl: ast::decl =>
		yield decl;
	};

	const tdecl = decl.decl as []ast::decl_type;
	if (len(tdecl) != 1) {
		fmt::fatal("Multiple type declarations are unsupported");
	};
	const tdecl = tdecl[0];
	const of = types::lookup(store, tdecl._type)!;
	types::newalias(store, tdecl.ident, of);
};

fn parseioctl(store: *types::typestore, d: dir, params: str) ioctl = {
	let buf = memio::fixed(strings::toutf8(params));
	let sc = bufio::newscanner(&buf);
	defer bufio::finish(&sc);
	let lex = lex::init(&sc, "<ioctl>");

	const rn = expect(&lex, ltok::LIT_RCONST).1 as rune;
	expect(&lex, ltok::COMMA);
	const num = expect(&lex, ltok::LIT_ICONST).1 as u64;

	if (d == dir::IO) {
		return (d, rn, num: u32, null);
	};

	expect(&lex, ltok::COMMA);
	const ty = match (parse::_type(&lex)) {
	case let ty: ast::_type =>
		yield ty;
	case let err: parse::error =>
		fmt::fatal("Error:", parse::strerror(err));
	};

	const ty = match (types::lookup(store, &ty)) {
	case let err: types::error =>
		fmt::fatal("Error:", types::strerror(err));
	case types::deferred =>
		fmt::fatal("Error: this tool does not support forward references");
	case let ty: const *types::_type =>
		yield ty;
	};

	return (d, rn, num: u32, ty);
};

fn expect(lex: *lex::lexer, want: ltok) lex::token = {
	match (lex::lex(lex)) {
	case let err: lex::error =>
		fmt::fatal("Error:", lex::strerror(err));
	case let tok: lex::token =>
		if (tok.0 != want) {
			fmt::fatalf("Error: unexpected {}", lex::tokstr(tok));
		};
		return tok;
	};
};

def IOC_NRBITS: u32 = 8;
def IOC_TYPEBITS: u32 = 8;
def IOC_SIZEBITS: u32 = 14; // XXX: Arch-specific
def IOC_DIRBITS: u32 = 2; // XXX: Arch-specific

def IOC_NRSHIFT: u32 = 0;
def IOC_TYPESHIFT: u32 = IOC_NRSHIFT + IOC_NRBITS;
def IOC_SIZESHIFT: u32 = IOC_TYPESHIFT + IOC_TYPEBITS;
def IOC_DIRSHIFT: u32 = IOC_SIZESHIFT + IOC_SIZEBITS;

fn ioctlno(io: *ioctl) u32 = {
	const ty = match (io.3) {
	case let ty: const *types::_type =>
		yield ty.sz;
	case null =>
		yield 0z;
	};
	return (io.0: u32 << IOC_DIRSHIFT) |
		(io.1: u32 << IOC_TYPESHIFT) |
		(io.2 << IOC_NRSHIFT) |
		(ty: u32 << IOC_SIZESHIFT);
};
