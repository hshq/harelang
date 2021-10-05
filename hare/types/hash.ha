use endian;
use hash::fnv;
use hash;
use strings;
use fmt;

// Keep ordered with respect to bootstrap harec:include/types.h
type storage = enum u8 {
	BOOL, CHAR, F32, F64, I16, I32, I64, I8, INT, NULL, RUNE, SIZE, STRING,
	U16, U32, U64, U8, UINT, UINTPTR, VOID, TYPE, ALIAS, ARRAY, ENUM,
	FUNCTION, POINTER, SLICE, STRUCT, TAGGED, TUPLE, UNION,
};

fn builtin_storage(b: builtin) u8 = {
	switch (b) {
	case builtin::BOOL =>
		return storage::BOOL;
	case builtin::CHAR =>
		return storage::CHAR;
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
	case builtin::NULL =>
		return storage::NULL;
	case builtin::RUNE =>
		return storage::RUNE;
	case builtin::SIZE =>
		return storage::SIZE;
	case builtin::STR =>
		return storage::STRING;
	case builtin::TYPE =>
		return storage::TYPE;
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
	case builtin::VOID =>
		return storage::VOID;
	};
};

fn type_storage(t: *_type) u8 = {
	match (t.repr) {
	case alias =>
		return storage::ALIAS;
	case array =>
		return storage::ARRAY;
	case b: builtin =>
		return builtin_storage(b);
	case _enum =>
		return storage::ENUM;
	case func =>
		return storage::FUNCTION;
	case pointer =>
		return storage::POINTER;
	case slice =>
		return storage::SLICE;
	case st: _struct =>
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
	case a: alias =>
		for (let i = len(a.id); i > 0; i -= 1) {
			hash::write(&id, strings::toutf8(a.id[i - 1]));
			write8(&id, 0);
		};
	case a: array =>
		write32(&id, hash(a.member));
		static assert(size(u64) == size(size)); // TODO
		write64(&id, a.length);
	case builtin => void;
	case e: _enum =>
		write8(&id, builtin_storage(e.storage));
		for (let i = 0z; i < len(e.values); i += 1) {
			hash::write(&id, strings::toutf8(e.values[i].0));
			write64(&id, e.values[i].1);
		};
	case f: func =>
		write32(&id, hash(f.result));
		write8(&id, f.variadism: u8);
		write8(&id, f.flags: u8);
		for (let i = 0z; i < len(f.params); i += 1) {
			write32(&id, hash(f.params[i]));
		};
	case p: pointer =>
		write8(&id, p.flags);
		write32(&id, hash(p.referent));
	case s: slice =>
		write32(&id, hash(s));
	case st: _struct =>
		for (let i = 0z; i < len(st.fields); i += 1) {
			const field = st.fields[i];
			hash::write(&id, strings::toutf8(field.name));
			write32(&id, hash(field._type));
			static assert(size(u64) == size(size)); // TODO
			write64(&id, field.offs);
		};
	case tu: tuple =>
		for (let i = 0z; i < len(tu); i += 1) {
			write32(&id, hash(tu[i]._type));
		};
	case ta: tagged =>
		for (let i = 0z; i < len(ta); i += 1) {
			write32(&id, hash(ta[i]));
		};
	};

	return fnv::sum32(&id);
};

@test fn hash() void = {
	// Test a few samples for ABI compatibility with harec
	let sample = _type {
		flags = flags::NONE,
		repr = builtin::STR,
	};
	assert(hash(&sample) == 2843771249);

	let sample = _type {
		flags = flags::NONE,
		repr = alias {
			id = ["foo", "bar"],
			...
		},
	};
	assert(hash(&sample) == 385303307);

	let sample = _type {
		flags = flags::ERROR,
		repr = alias {
			id = ["foo", "bar"],
			...
		},
	};
	assert(hash(&sample) == 4117101293);

	let _int = _type {
		flags = flags::NONE,
		repr = builtin::INT,
	};
	assert(hash(&_int) == 1099590421);

	let sample = _type {
		flags = flags::NONE,
		repr = pointer {
			referent = &_int,
			flags = pointer_flags::NONE,
		},
	};
	assert(hash(&sample) == 2081672869);

	let sample = _type {
		flags = flags::NONE,
		repr = pointer {
			referent = &_int,
			flags = pointer_flags::NULLABLE,
		},
	};
	assert(hash(&sample) == 841481858);

	let sample = _type {
		flags = flags::NONE,
		repr = _struct {
			kind = struct_union::STRUCT,
			fields = [
				struct_field {
					name = "bar",
					offs = 4,
					_type = &_int,
				},
				struct_field {
					name = "foo",
					offs = 0,
					_type = &_int,
				},
			],
		},
	};
	assert(hash(&sample) == 2453524063);

	let sample = _type {
		flags = flags::NONE,
		repr = [
			tuple_value {
				offs = 0,
				_type = &_int,
			},
			tuple_value {
				offs = 4,
				_type = &_int,
			},
			tuple_value {
				offs = 8,
				_type = &_int,
			},
		],
	};
	assert(hash(&sample) == 2230759349);

	let sample = _type {
		flags = flags::NONE,
		repr = array {
			length = 5,
			member = &_int,
		},
	};
	assert(hash(&sample) == 3903522747);

	let _uint = _type {
		flags = flags::NONE,
		repr = builtin::UINT,
	};
	let _void = _type {
		flags = flags::NONE,
		repr = builtin::VOID,
	};

	let sample = _type {
		flags = flags::NONE,
		repr = [
			&_int,
			&_uint,
			&_void,
		]: tagged,
	};
	assert(hash(&sample) == 2847927164);

	let sample = _type {
		flags = flags::NONE,
		repr = _enum {
			storage = builtin::INT,
			values = [
				("FOO", 0),
				("BAR", 42),
				("BAZ", 69),
			],
		},
	};
	assert(hash(&sample) == 94471087);

	let sample = _type {
		flags = flags::NONE,
		repr = func {
			result = &_void,
			variadism = variadism::C,
			flags = func_flags::NORETURN,
			params = [&_uint, &_int],
		},
	};
	assert(hash(&sample) == 1223530078);

	let sample = _type {
		flags = flags::NONE,
		repr = &_void: slice,
	};
	assert(hash(&sample) == 263911532);
};
