use types;

// Returns the absolute value of signed integer n.
export fn absi8(n: i8) i8 = {
	if (n < 0i8) {
		return -n;
	} else {
		return n;
	};
};

// Returns the absolute value of signed integer n.
export fn absi16(n: i16) i16 = {
	if (n < 0i16) {
		return -n;
	} else {
		return n;
	};
};

// Returns the absolute value of signed integer n.
export fn absi32(n: i32) i32 = {
	if (n < 0i32) {
		return -n;
	} else {
		return n;
	};
};

// Returns the absolute value of signed integer n.
export fn absi64(n: i64) i64 = {
	if (n < 0i64) {
		return -n;
	} else {
		return n;
	};
};

// Returns the absolute value of signed integer n.
export fn absi(n: types::integer) i64 = {
	match (n) {
	case let n: i8 =>
		return (absi8(n): i64);
	case let n: i16 =>
		return (absi16(n): i64);
	case let n: i32 =>
		return (absi32(n): i64);
	case let n: i64 =>
		return (absi64(n): i64);
	case let n: int =>
		return (absi64(n): i64);
	};
};

@test fn absi() void = {
	assert(absi8(2i8) == 2i8);
	assert(absi8(-2i8) == 2i8);
	assert(absi16(2i16) == 2i16);
	assert(absi16(-2i16) == 2i16);
	assert(absi32(2i32) == 2i32);
	assert(absi32(-2i32) == 2i32);
	assert(absi64(2i64) == 2i64);
	assert(absi64(-2i64) == 2i64);
	assert(absi(2i8) == 2i64);
	assert(absi(-2i8) == 2i64);
	assert(absi(2i16) == 2i64);
	assert(absi(-2i16) == 2i64);
	assert(absi(2i32) == 2i64);
	assert(absi(-2i32) == 2i64);
	assert(absi(2i64) == 2i64);
	assert(absi(-2i64) == 2i64);
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi8(n: i8) i8 = {
	if (n > 0i8) {
		return 1i8;
	};
	if (n < 0i8) {
		return -1i8;
	};
	return 0i8;
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi16(n: i16) i16 = {
	if (n > 0i16) {
		return 1i16;
	};
	if (n < 0i16) {
		return -1i16;
	};
	return 0i16;
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi32(n: i32) i32 = {
	if (n > 0i32) {
		return 1i32;
	};
	if (n < 0i32) {
		return -1i32;
	};
	return 0i32;
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi64(n: i64) i64 = {
	if (n > 0i64) {
		return 1i64;
	};
	if (n < 0i64) {
		return -1i64;
	};
	return 0i64;
};

// Return 1 if n is positive, -1 if it's negative and 0 if it's 0.
export fn signi(n: types::integer) i64 = {
	match (n) {
	case let n: i8 =>
		return (signi8(n): i64);
	case let n: i16 =>
		return (signi16(n): i64);
	case let n: i32 =>
		return (signi32(n): i64);
	case let n: i64 =>
		return (signi64(n): i64);
	case let n: int =>
		return (signi64(n): i64);
	};
};

@test fn signi() void = {
	assert(signi8(2i8) == 1i8);
	assert(signi8(-2i8) == -1i8);
	assert(signi8(0i8) == 0i8);
	assert(signi16(2i16) == 1i16);
	assert(signi16(-2i16) == -1i16);
	assert(signi16(0i16) == 0i16);
	assert(signi32(2i32) == 1i32);
	assert(signi32(-2i32) == -1i32);
	assert(signi32(0i32) == 0i32);
	assert(signi64(2i64) == 1i64);
	assert(signi64(-2i64) == -1i64);
	assert(signi64(0i64) == 0i64);
	assert(signi(2i16) == 1i64);
	assert(signi(-2i16) == -1i64);
	assert(signi(0i16) == 0i64);
};
