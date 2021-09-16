// Returns true if the given type is a signed type.
export fn is_signed(ty: const *_type) bool = {
	match (ty.repr) {
	case al: alias =>
		// TODO: al.secondary as *_type
		return is_signed(al.secondary: const *_type);
	case bi: builtin =>
		switch (bi) {
		case builtin::F32, builtin::F64, builtin::I16, builtin::I32,
		builtin::I64, builtin::I8, builtin::INT =>
			return true;
		case =>
			return false;
		};
	case e: _enum =>
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
	case al: alias =>
		// TODO: al.secondary as *_type
		return is_float(al.secondary: const *_type);
	case bi: builtin =>
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
	case al: alias =>
		// TODO: al.secondary as *_type
		return is_integer(al.secondary: const *_type);
	case bi: builtin =>
		switch (bi) {
			case builtin::INT, builtin::UINT, builtin::I16,
			builtin::I32, builtin::I64, builtin::I8, builtin::U16,
			builtin::U32, builtin::U64, builtin::U8, builtin::CHAR,
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
