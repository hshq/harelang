// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Returns true if the given type is a signed type.
export fn is_signed(ty: const *_type) bool = {
	match (ty.repr) {
	case let al: alias =>
		return is_signed(al.secondary as const *_type);
	case let bi: builtin =>
		switch (bi) {
		case builtin::F32, builtin::F64, builtin::I16, builtin::I32,
		builtin::I64, builtin::I8, builtin::INT =>
			return true;
		case =>
			return false;
		};
	case let e: _enum =>
		switch (e.storage) {
		case builtin::I16, builtin::I32, builtin::I64, builtin::I8,
		builtin::INT =>
			return true;
		case =>
			return false;
		};
	case =>
		return false;
	};
};

// Returns true if the given type is a floating-point type.
export fn is_float(ty: const *_type) bool = {
	match (ty.repr) {
	case let al: alias =>
		return is_float(al.secondary as const *_type);
	case let bi: builtin =>
		switch (bi) {
		case builtin::F32, builtin::F64 =>
			return true;
		case =>
			return false;
		};
	case =>
		return false;
	};
};

// Returns true if the given type is an integer type.
export fn is_integer(ty: const *_type) bool = {
	match (ty.repr) {
	case let al: alias =>
		return is_integer(al.secondary as const *_type);
	case let bi: builtin =>
		switch (bi) {
			case builtin::INT, builtin::UINT, builtin::I16,
			builtin::I32, builtin::I64, builtin::I8, builtin::U16,
			builtin::U32, builtin::U64, builtin::U8,
			builtin::SIZE, builtin::UINTPTR =>
				return true;
			case =>
				return false;
		};
	case _enum =>
		return true;
	case =>
		return false;
	};
};
