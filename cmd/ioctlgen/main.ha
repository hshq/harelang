use bufio;
use fmt;
use hare::ast;
use hare::lex;
use hare::lex::{ltok};
use hare::parse;
use hare::types;
use io;
use os;
use regex;
use strings;

let ioctlre: regex::regex = regex::regex { ... };

@init fn init() void = {
	ioctlre = regex::compile(`@(_IO[RW]*)\((.*)\)`)!;
};

@fini fn fini() void = {
	regex::regex_finish(&ioctlre);
};

type dir = enum u64 {
	IO = 0,
	IOW = 1,
	IOR = 2,
	IOWR = IOW | IOR,
};

type ioctl = (dir, rune, u64, const nullable *types::_type);

export fn main() void = {
	// TODO: Configurable arch
	const store = types::store(types::x86_64, null, null);
	defer types::store_free(store);

	for (true) {
		const line = match (bufio::scanline(os::stdin)!) {
		case io::EOF =>
			break;
		case let line: []u8 =>
			yield strings::fromutf8(line);
		};
		defer free(line);

		let groups = match (regex::find(&ioctlre, line)!) {
		case void =>
			fmt::println(line)!;
			continue;
		case let cap: []regex::capture =>
			yield cap;
		};
		defer free(groups);

		const dir = switch (groups[1].content) {
		case "_IO" =>
			yield dir::IO;
		case "_IOR" =>
			yield dir::IOR;
		case "_IOW" =>
			yield dir::IOW;
		case "_IOWR" =>
			yield dir::IOWR;
		};
		const ioctl = parseioctl(store, dir, groups[2].content);

		const prefix = strings::sub(line, 0, groups[1].start - 1);
		fmt::printfln("{}0x{:x};", prefix, ioctlno(&ioctl))!;
	};
};

fn parseioctl(store: *types::typestore, d: dir, params: str) ioctl = {
	const buf = bufio::fixed(strings::toutf8(params), io::mode::READ);
	const lex = lex::init(&buf, "<ioctl>");

	const rn = expect(&lex, ltok::LIT_RUNE).1 as rune;
	expect(&lex, ltok::COMMA);
	const num = expect(&lex, ltok::LIT_ICONST).1 as i64;

	if (d == dir::IO) {
		return (d, rn, num: u64, null);
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
		fmt::fatal("Error: this tool does not support reverse declarations");
	case let ty: const *types::_type =>
		yield ty;
	};

	return (d, rn, num: u64, ty);
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

def IOC_NRBITS: u64 = 8;
def IOC_TYPEBITS: u64 = 8;
def IOC_SIZEBITS: u64 = 14; // XXX: Arch-specific
def IOC_DIRBITS: u64 = 2; // XXX: Arch-specific

def IOC_NRSHIFT: u64 = 0;
def IOC_TYPESHIFT: u64 = IOC_NRSHIFT + IOC_NRBITS;
def IOC_SIZESHIFT: u64 = IOC_TYPESHIFT + IOC_TYPEBITS;
def IOC_DIRSHIFT: u64 = IOC_SIZESHIFT + IOC_SIZEBITS;

fn ioctlno(io: *ioctl) u64 = {
	const ty = match (io.3) {
	case let ty: const *types::_type =>
		yield ty.sz;
	case null =>
		yield 0z;
	};
	return (io.0: u64 << IOC_DIRSHIFT) |
		(io.1: u32: u64 << IOC_TYPESHIFT) |
		(io.2 << IOC_NRSHIFT) |
		(ty: u64 << IOC_SIZESHIFT);
};
