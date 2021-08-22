use endian;
use hash::fnv;
use hash;
use strings;

// Keep ordered with respect to bootstrap harec:include/types.h
type storage = enum u8 {
	BOOL, CHAR, ENUM, F32, F64, FCONST, I16, I32, I64, I8, ICONST, INT,
	NULL, RUNE, SIZE, U16, U32, U64, U8, UINT, UINTPTR, VOID, ALIAS, ARRAY,
	FUNCTION, POINTER, SLICE, STRING, STRUCT, TAGGED, TUPLE, UNION,
};

fn builtin_storage(b: builtin) u8 = switch (b) {
	builtin::BOOL => storage::BOOL,
	builtin::CHAR => storage::CHAR,
	builtin::F32 => storage::F32,
	builtin::F64 => storage::F64,
	builtin::I16 => storage::I16,
	builtin::I32 => storage::I32,
	builtin::I64 => storage::I64,
	builtin::I8 => storage::I8,
	builtin::INT => storage::INT,
	builtin::NULL => storage::NULL,
	builtin::RUNE => storage::RUNE,
	builtin::SIZE => storage::SIZE,
	builtin::STR => storage::STRING,
	builtin::U16 => storage::U16,
	builtin::U32 => storage::U32,
	builtin::U64 => storage::U64,
	builtin::U8 => storage::U8,
	builtin::UINT => storage::UINT,
	builtin::UINTPTR => storage::UINTPTR,
	builtin::VOID => storage::VOID,
};

fn type_storage(t: *_type) u8 = match (t.repr) {
	alias => storage::ALIAS,
	array => storage::ARRAY,
	b: builtin => builtin_storage(b),
	_enum => storage::ENUM,
	func => storage::FUNCTION,
	pointer => storage::POINTER,
	slice => storage::SLICE,
	st: _struct =>
		if (st.kind == struct_union::STRUCT)
			storage::STRUCT
		else storage::UNION,
	tuple => storage::TUPLE,
	tagged => storage::TAGGED,
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
	defer hash::close(id);
	write8(id, type_storage(t));
	write8(id, t.flags);

	match (t.repr) {
		a: alias => for (let i = len(a.id); i > 0; i -= 1) {
			hash::write(id, strings::toutf8(a.id[i - 1]));
			write8(id, 0);
		},
		a: array => {
			write32(id, hash(a.member));
			static assert(size(u64) == size(size)); // TODO
			write64(id, a.length);
		},
		builtin => void,
		e: _enum => {
			write8(id, builtin_storage(e.storage));
			for (let i = 0z; i < len(e.values); i += 1) {
				hash::write(id, strings::toutf8(e.values[i].0));
				write64(id, e.values[i].1);
			};
		},
		f: func => {
			write32(id, hash(f.result));
			write8(id, f.variadism: u8);
			write8(id, f.flags: u8);
			for (let i = 0z; i < len(f.params); i += 1) {
				write32(id, hash(f.params[i]));
			};
		},
		p: pointer => {
			write8(id, p.flags);
			write32(id, hash(p.referent));
		},
		s: slice => write32(id, hash(s)),
		st: _struct => for (let i = 0z; i < len(st.fields); i += 1) {
			const field = st.fields[i];
			hash::write(id, strings::toutf8(field.name));
			write32(id, hash(field._type));
			static assert(size(u64) == size(size)); // TODO
			write64(id, field.offs);
		},
		tu: tuple => for (let i = 0z; i < len(tu); i += 1) {
			write32(id, hash(tu[i]._type));
		},
		ta: tagged => for (let i = 0z; i < len(ta); i += 1) {
			write32(id, hash(ta[i]));
		},
	};

	return fnv::sum32(id);
};

@test fn hash() void = {
	// Test a few samples for ABI compatibility with harec
	let sample = _type {
		flags = flags::NONE,
		_type = builtin::STR,
	};
	assert(hash(&sample) == 3350498318);

	let sample = _type {
		flags = flags::NONE,
		_type = alias {
			id = ["foo", "bar"],
			...
		},
	};
	assert(hash(&sample) == 1488828140);

	let sample = _type {
		flags = flags::ERROR,
		_type = alias {
			id = ["foo", "bar"],
			...
		},
	};
	assert(hash(&sample) == 4003927486);

	let _int = _type {
		flags = flags::NONE,
		_type = builtin::INT,
	};
	assert(hash(&_int) == 1737287038);

	let sample = _type {
		flags = flags::NONE,
		_type = pointer {
			referent = &_int,
			flags = pointer_flags::NONE,
		},
	};
	assert(hash(&sample) == 1453816944);

	let sample = _type {
		flags = flags::NONE,
		_type = pointer {
			referent = &_int,
			flags = pointer_flags::NULLABLE,
		},
	};
	assert(hash(&sample) == 1467299071);

	let sample = _type {
		flags = flags::NONE,
		_type = _struct {
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
	assert(hash(&sample) == 3615159786);

	let sample = _type {
		flags = flags::NONE,
		_type = [
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
	assert(hash(&sample) == 4136455899);

	let sample = _type {
		flags = flags::NONE,
		_type = array {
			length = 5,
			member = &_int,
		},
	};
	assert(hash(&sample) == 2972813387);

	let _uint = _type {
		flags = flags::NONE,
		_type = builtin::UINT,
	};
	let _void = _type {
		flags = flags::NONE,
		_type = builtin::VOID,
	};

	let sample = _type {
		flags = flags::NONE,
		_type = [
			&_int,
			&_uint,
			&_void,
		]: tagged,
	};
	assert(hash(&sample) == 3951208153);

	let sample = _type {
		flags = flags::NONE,
		_type = _enum {
			storage = builtin::INT,
			values = [
				("FOO", 0),
				("BAR", 42),
				("BAZ", 69),
			],
		},
	};
	assert(hash(&sample) == 1838699449);

	let sample = _type {
		flags = flags::NONE,
		_type = func {
			result = &_void,
			variadism = variadism::C,
			flags = func_flags::NORETURN,
			params = [&_uint, &_int],
		},
	};
	assert(hash(&sample) == 1706980510);

	let sample = _type {
		flags = flags::NONE,
		_type = &_void: slice,
	};
	assert(hash(&sample) == 3143795781);
};
