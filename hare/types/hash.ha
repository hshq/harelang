// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use endian;
use hash;
use hash::fnv;
use strings;

// Keep ordered with respect to bootstrap harec:include/types.h
type storage = enum u8 {
	BOOL, DONE, F32, F64, I16, I32, I64, I8, INT, NEVER, NULL, OPAQUE, RUNE,
	SIZE, STRING, U16, U32, U64, U8, UINT, UINTPTR, VOID, ALIAS, ARRAY,
	ENUM, FUNCTION, POINTER, SLICE, STRUCT, TAGGED, TUPLE, UNION, VALIST,
};

fn builtin_storage(b: builtin) u8 = {
	switch (b) {
	case builtin::BOOL =>
		return storage::BOOL;
	case builtin::DONE =>
		return storage::DONE;
	case builtin::F32 =>
		return storage::F32;
	case builtin::F64 =>
		return storage::F64;
	case builtin::I16 =>
		return storage::I16;
	case builtin::I32 =>
		return storage::I32;
	case builtin::I64 =>
		return storage::I64;
	case builtin::I8 =>
		return storage::I8;
	case builtin::INT =>
		return storage::INT;
	case builtin::NEVER =>
		return storage::NEVER;
	case builtin::NULL =>
		return storage::NULL;
	case builtin::OPAQUE =>
		return storage::OPAQUE;
	case builtin::RUNE =>
		return storage::RUNE;
	case builtin::SIZE =>
		return storage::SIZE;
	case builtin::STR =>
		return storage::STRING;
	case builtin::U16 =>
		return storage::U16;
	case builtin::U32 =>
		return storage::U32;
	case builtin::U64 =>
		return storage::U64;
	case builtin::U8 =>
		return storage::U8;
	case builtin::UINT =>
		return storage::UINT;
	case builtin::UINTPTR =>
		return storage::UINTPTR;
	case builtin::VALIST =>
		return storage::VALIST;
	case builtin::VOID =>
		return storage::VOID;
	case builtin::FCONST, builtin::ICONST, builtin::RCONST =>
		abort(); // unreachable
	};
};

fn type_storage(t: *_type) u8 = {
	match (t.repr) {
	case alias =>
		return storage::ALIAS;
	case array =>
		return storage::ARRAY;
	case let b: builtin =>
		return builtin_storage(b);
	case _enum =>
		return storage::ENUM;
	case func =>
		return storage::FUNCTION;
	case pointer =>
		return storage::POINTER;
	case slice =>
		return storage::SLICE;
	case let st: _struct =>
		if (st.kind == struct_union::STRUCT) {
			return storage::STRUCT;
		} else {
			return storage::UNION;
		};
	case tuple =>
		return storage::TUPLE;
	case tagged =>
		return storage::TAGGED;
	};
};

fn write8(h: *hash::hash, u: u8) void = {
	let buf = &u: *[*]u8;
	hash::write(h, buf[..1]);
};

fn write32(h: *hash::hash, u: u32) void = {
	static let buf: [size(u32)]u8 = [0...];
	endian::leputu32(buf, u);
	hash::write(h, buf);
};

fn write64(h: *hash::hash, u: u64) void = {
	static let buf: [size(u64)]u8 = [0...];
	endian::leputu64(buf, u);
	hash::write(h, buf);
};

// Returns the hash of a type. These hashes are deterministic and universally
// unique: different computers will generate the same hash for the same type.
export fn hash(t: *_type) u32 = {
	// Note that this function should produce the same hashes as harec; see
	// bootstrap harec:src/types.c:type_hash
	let id = fnv::fnv32a();
	write8(&id, type_storage(t));
	write8(&id, t.flags);

	match (t.repr) {
	case let a: alias =>
		for (let i = len(a.id); i > 0; i -= 1) {
			hash::write(&id, strings::toutf8(a.id[i - 1]));
			write8(&id, 0);
		};
	case let a: array =>
		write32(&id, hash(a.member));
		writesize(&id, a.length);
	case builtin => void;
	case let e: _enum =>
		write8(&id, builtin_storage(e.storage));
		for (let i = 0z; i < len(e.values); i += 1) {
			hash::write(&id, strings::toutf8(e.values[i].0));
			write64(&id, e.values[i].1);
		};
	case let f: func =>
		write32(&id, hash(f.result));
		write8(&id, f.variadism: u8);
		for (let i = 0z; i < len(f.params); i += 1) {
			write32(&id, hash(f.params[i]));
		};
	case let p: pointer =>
		write8(&id, p.flags);
		write32(&id, hash(p.referent));
	case let s: slice =>
		write32(&id, hash(s));
	case let st: _struct =>
		for (let i = 0z; i < len(st.fields); i += 1) {
			const field = st.fields[i];
			hash::write(&id, strings::toutf8(field.name));
			write32(&id, hash(field._type));
			writesize(&id, field.offs);
		};
	case let tu: tuple =>
		for (let i = 0z; i < len(tu); i += 1) {
			write32(&id, hash(tu[i]._type));
		};
	case let ta: tagged =>
		for (let i = 0z; i < len(ta); i += 1) {
			write32(&id, hash(ta[i]));
		};
	};

	return fnv::sum32(&id);
};
