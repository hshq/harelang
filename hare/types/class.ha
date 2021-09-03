// Returns true if the given type is a signed type.
export fn is_signed(ty: const *_type) bool = {
	return match (ty.repr) {
		// TODO: al.secondary as *_type
		al: alias => is_signed(al.secondary: const *_type),
		bi: builtin => switch (bi) {
			builtin::F32, builtin::F64,
			builtin::I16, builtin::I32, builtin::I64, builtin::I8,
			builtin::INT => true,
			* => false,
		},
		e: _enum => switch (e.storage) {
			builtin::I16, builtin::I32, builtin::I64, builtin::I8,
			builtin::INT => true,
			* => false,
		},
		* => false,
	};
};

// Returns true if the given type is a floating-point type.
export fn is_float(ty: const *_type) bool = {
	return match (ty.repr) {
		// TODO: al.secondary as *_type
		al: alias => is_float(al.secondary: const *_type),
		bi: builtin => switch (bi) {
			builtin::F32, builtin::F64 => true,
			* => false,
		},
		* => false,
	};
};

// Returns true if the given type is an integer type.
export fn is_integer(ty: const *_type) bool = {
	return match (ty.repr) {
		// TODO: al.secondary as *_type
		al: alias => is_integer(al.secondary: const *_type),
		bi: builtin => switch (bi) {
			builtin::INT, builtin::UINT,
			builtin::I16, builtin::I32, builtin::I64, builtin::I8,
			builtin::U16, builtin::U32, builtin::U64, builtin::U8,
			builtin::CHAR, builtin::SIZE, builtin::UINTPTR => true,
			* => false,
		},
		_enum => true,
		* => false,
	};
};
