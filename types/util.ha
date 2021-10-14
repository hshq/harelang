// Returns the value of the enum at "val" as a string. Aborts if the value is
// not present. Note that this does not work with enums being used as a flag
// type, see [[strflag]] instead.
export fn strenum(ty: type, val: *void) str = {
	const ty = unwrap(ty);
	const en = ty.repr as enumerated;
	const value: u64 = switch (en.storage) {
	case builtin::CHAR, builtin::I8, builtin::U8 =>
		yield *(val: *u8);
	case builtin::I16, builtin::U16 =>
		yield *(val: *u16);
	case builtin::I32, builtin::U32 =>
		yield *(val: *u32);
	case builtin::I64, builtin::U64 =>
		yield *(val: *u64);
	case builtin::INT, builtin::UINT =>
		yield switch (size(int)) {
		case 4 =>
			yield *(val: *u32);
		case 8 =>
			yield *(val: *u64);
		case => abort();
		};
	case builtin::SIZE =>
		yield switch (size(size)) {
		case 4 =>
			yield *(val: *u32);
		case 8 =>
			yield *(val: *u64);
		case => abort();
		};
	case => abort();
	};

	for (let i = 0z; i < len(en.values); i += 1) {
		if (en.values[i].1.u == value) {
			return en.values[i].0;
		};
	};

	abort("enum has invalid value");
};

// TODO: should we have a static version of that?

// Returns the names of enabled flags of a bitfield enum at "val" formatted as
// '|' operation, or "0" when the value doesn't match any flags. The string
// must be freed by the caller.
export fn strflag(ty: type, val: *void) str = {
	const ty = unwrap(ty);
	const en = ty.repr as enumerated;
	const value: u64 = switch (en.storage) {
	case builtin::CHAR, builtin::I8, builtin::U8 =>
		yield *(val: *u8);
	case builtin::I16, builtin::U16 =>
		yield *(val: *u16);
	case builtin::I32, builtin::U32 =>
		yield *(val: *u32);
	case builtin::I64, builtin::U64 =>
		yield *(val: *u64);
	case builtin::INT, builtin::UINT =>
		yield switch (size(int)) {
		case 4 =>
			yield *(val: *u32);
		case 8 =>
			yield *(val: *u64);
		case => abort();
		};
	case builtin::SIZE =>
		yield switch (size(size)) {
		case 4 =>
			yield *(val: *u32);
		case 8 =>
			yield *(val: *u64);
		case => abort();
		};
	case => abort();
	};

	let buf: []u8 = alloc([]);

	for (let i = 0z; i < len(en.values); i += 1) {
		if (en.values[i].1.u & value != 0) {
			if (i > 0) {
				append(buf, '|': u8);
			};
			const name = en.values[i].0;
			append(buf, *(&name: *[]u8)...);
		};
	};

	if (len(buf) == 0) {
		append(buf, '0': u8);
	};

	return *(&buf: *str);
};

// Returns [[typeinfo]] for the provided type, unwrapping any aliases along the
// way.
export fn unwrap(in: type) const *typeinfo = {
	let info = reflect(in);
	match (info.repr) {
	case a: alias =>
		return unwrap(a.secondary);
	case =>
		return info;
	};
};
