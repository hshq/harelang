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
		if (en.values[i].1 == value) {
			return en.values[i].0;
		};
	};

	abort("enum has invalid value");
};
