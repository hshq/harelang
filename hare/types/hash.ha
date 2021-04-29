use endian;
use hash::fnv;
use hash;
use strings;
use fmt;

// Keep ordered with respect to bootstrap harec:include/types.h
type storage = enum u8 {
	BOOL, CHAR, ENUM, F32, F64, FCONST, I16, I32, I64, I8, ICONST, INT,
	NULL, RUNE, SIZE, U16, U32, U64, U8, UINT, UINTPTR, VOID, ALIAS, ARRAY,
	FUNCTION, POINTER, SLICE, STRING, STRUCT, TAGGED, TUPLE, UNION,
};

fn type_storage(t: *_type) u8 = match (t._type) {
	alias => storage::ALIAS,
	t: builtin => switch (t) {
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
	},
	* => abort(), // TODO
};

fn write8(h: *hash::hash, u: u8) void = {
	let buf = &u: *[*]u8;
	hash::write(h, buf[..1]);
};

// Returns the hash of a type. These hashes are deterministic and universally
// unique: different computers will generate the same hash for the same type.
export fn hash(t: *_type) u32 = {
	// Note that this function should produce the same hashes as harec; see
	// bootstrap harec:src/types.c:type_hash
	let hash = fnv::fnv32a();
	defer hash::close(hash);
	write8(hash, type_storage(t));
	write8(hash, t.flags);

	match (t._type) {
		a: alias => for (let i = 0z; i < len(a); i += 1) {
			hash::write(hash, strings::toutf8(a[i]));
			write8(hash, 0);
		},
		builtin => void,
	};

	return fnv::sum32(hash);
};

@test fn hash() void = {
	// Test a few samples for ABI compatibility with harec
	let sample = _type {
		flags = flags::NONE,
		_type = builtin::STR,
	};
	fmt::errorfln("{}", hash(&sample))!;
	assert(hash(&sample) == 3350498318);

	// TODO: more samples
};
