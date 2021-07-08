// The floating point value representing Not a Number, i.e. an undefined or
// unrepresentable value. You cannot test if a number is NaN by comparing to
// this value; see [[isnan]] instead.
export def NAN: f32 = 0.0 / 0.0;

// The floating point value representing positive infinity. Use -[[INF]] for
// negative infinity.
export def INF: f32 = 1.0 / 0.0;

// Returns true if the given floating-point number is NaN.
export fn isnan(n: f64) bool = n != n;

@test fn isnan() void = {
	assert(isnan(NAN));
	assert(isnan(-NAN));
	assert(isnan(f64frombits(0xfffabcdef1234567)));
	assert(!isnan(INF));
	assert(!isnan(1.23f32));
};

// Returns true if the given floating-point number is infinite.
export fn isinf(n: f64) bool = {
	const bits = f64bits(n);
	const mant = bits & F64_MANTISSA_MASK;
	const exp = bits >> F64_MANTISSA_BITS & F64_EXPONENT_MASK;
	return exp == F64_EXPONENT_MASK && mant == 0;
};

@test fn isinf() void = {
	assert(isinf(INF));
	assert(isinf(-INF));
	assert(!isinf(NAN));
	assert(!isinf(1.23));
	assert(!isinf(-1.23f32));
};

// Returns true if the given floating-point number is normal.
export fn isnormal(n: (f32 | f64)) bool = {
	return match (n) {
		n: f32 => isnormalf32(n),
		n: f64 => isnormalf64(n),
	};
};

// Returns true if the given f32 is normal.
export fn isnormalf32(n: f32) bool = {
	const bits = f32bits(n);
	const mant = bits & F32_MANTISSA_MASK;
	const exp = bits >> F32_MANTISSA_BITS & F32_EXPONENT_MASK;
	return exp != F32_EXPONENT_MASK && (exp > 0 || mant == 0);
};

// Returns true if the given f64 is normal.
export fn isnormalf64(n: f64) bool = {
	const bits = f64bits(n);
	const mant = bits & F64_MANTISSA_MASK;
	const exp = bits >> F64_MANTISSA_BITS & F64_EXPONENT_MASK;
	return exp != F64_EXPONENT_MASK && (exp > 0 || mant == 0);
};

// Returns true if the given floating-point number is subnormal.
export fn issubnormal(n: (f32 | f64)) bool = {
	return match (n) {
		n: f32 => issubnormalf32(n),
		n: f64 => issubnormalf64(n),
	};
};

// Returns true if the given f32 is subnormal.
export fn issubnormalf32(n: f32) bool = {
	const bits = f32bits(n);
	const mant = bits & F32_MANTISSA_MASK;
	const exp = bits >> F32_MANTISSA_BITS & F32_EXPONENT_MASK;
	return exp == 0 && mant != 0;
};

// Returns true if the given f64 is subnormal.
export fn issubnormalf64(n: f64) bool = {
	const bits = f64bits(n);
	const mant = bits & F64_MANTISSA_MASK;
	const exp = bits >> F64_MANTISSA_BITS & F64_EXPONENT_MASK;
	return exp == 0 && mant != 0;
};

@test fn float_normality() void = {
	assert(isnormal(0.0));
	assert(isnormal(1.0));
	assert(!isnormal(NAN));
	assert(!isnormal(INF));
	assert(!isnormal(1.0e-310));
	assert(!isnormal(1.0e-40f32));

	assert(isnormalf32(1.0));
	assert(isnormalf32(0.0));
	assert(!isnormalf32(NAN));
	assert(!isnormalf32(INF));
	assert(!isnormalf32(-1.0e-40));
	assert(isnormalf32(-1.0e-50));

	assert(isnormalf64(1.0));
	assert(isnormalf64(0.0));
	assert(!isnormalf64(NAN));
	assert(!isnormalf64(INF));
	assert(!isnormalf64(-1.0e-320));
	assert(isnormalf64(-1.0e-330));

	assert(issubnormal(1.0e-320));
	assert(issubnormal(1.0e-42f32));
	assert(!issubnormal(NAN));
	assert(!issubnormal(INF));
	assert(!issubnormal(1.0));
	assert(!issubnormal(0.0));

	assert(issubnormalf32(1.0e-45));
	assert(issubnormalf32(-1.0e-39));
	assert(!issubnormalf32(-NAN));
	assert(!issubnormalf32(-INF));
	assert(!issubnormalf32(0.0));
	assert(!issubnormalf32(-1.0e-49));

	assert(issubnormalf64(5.0e-324));
	assert(issubnormalf64(-2.0e-310));
	assert(!issubnormalf64(-NAN));
	assert(!issubnormalf64(-INF));
	assert(!issubnormalf64(-1.0e-400));
	assert(!issubnormalf64(0.0));
};

// Returns the binary representation of the given f64.
export fn f64bits(n: f64) u64 = *(&n: *u64);

// Returns the binary representation of the given f32.
export fn f32bits(n: f32) u32 = *(&n: *u32);

// Returns f64 with the given binary representation.
export fn f64frombits(n: u64) f64 = *(&n: *f64);

// Returns f32 with the given binary representation.
export fn f32frombits(n: u32) f32 = *(&n: *f32);

@test fn floatbits() void = {
	const a: [_]f64 = [INF, -INF, 0.0, 1.0, -1.0, 123456789.0,
		F64_MIN, F64_MIN_NORMAL, F64_MAX_NORMAL];
	for (let i = 0z; i < len(a); i += 1) {
		assert(f64frombits(f64bits(a[i])) == a[i]);
	};
	const a: [_]f32 = [INF, -INF, 0.0, 1.0, -1.0, -123456.0,
		F32_MIN, F32_MIN_NORMAL, F32_MAX_NORMAL];
	for (let i = 0z; i < len(a); i += 1) {
		assert(f32frombits(f32bits(a[i])) == a[i]);
	};
};

// The number of bits in the significand of the binary representation of f64.
export def F64_MANTISSA_BITS: u64 = 52;

// The number of bits in the exponent of the binary representation of f64.
export def F64_EXPONENT_BITS: u64 = 11;

// The bias of the exponent of the binary representation of f64. Subtract this
// from the exponent in the binary representation to get the actual exponent.
export def F64_EXPONENT_BIAS: u16 = 1023;

// The number of bits in the significand of the binary representation of f32.
export def F32_MANTISSA_BITS: u64 = 23;

// The number of bits in the exponent of the binary representation of f32.
export def F32_EXPONENT_BITS: u64 = 8;

// The bias of the exponent of the binary representation of f32. Subtract this
// from the exponent in the binary representation to get the actual exponent.
export def F32_EXPONENT_BIAS: u16 = 127;

def F64_MANTISSA_MASK: u64 = (1 << F64_MANTISSA_BITS) - 1;
def F64_EXPONENT_MASK: u64 = (1 << F64_EXPONENT_BITS) - 1;

def F32_MANTISSA_MASK: u64 = (1 << F32_MANTISSA_BITS) - 1;
def F32_EXPONENT_MASK: u64 = (1 << F32_EXPONENT_BITS) - 1;

// The largest representable f64 value which is less than Infinity.
export def F64_MAX_NORMAL: f64 = 1.7976931348623157e+308;

// The smallest representable normal f64 value.
export def F64_MIN_NORMAL: f64 = 2.2250738585072014e-308;

// THe smallest (subnormal) f64 value greater than zero.
export def F64_MIN: f64 = 5.0e-324;

// The largest representable f32 value which is less than Infinity.
export def F32_MAX_NORMAL: f32 = 3.4028234e+38;

// The smallest representable normal f32 value.
export def F32_MIN_NORMAL: f32 = 1.1754944e-38;

// The smallest (subnormal) f32 value greater than zero.
export def F32_MIN: f32 = 1.0e-45;

// Contains information about the structure of a specific floating point number
// type.
export type floatinfo = struct {
	// Bits in significand.
	mantbits: u64,
	// Bits in exponent.
	expbits: u64,
	// Bias of exponent.
	expbias: int,
	// Mask for mantissa.
	mantmask: u64,
	// Mask for exponent.
	expmask: u64,
};

// A [[floatinfo]] structure defining the structure of the f64 type.
export const f64info: floatinfo = floatinfo {
	mantbits = 52,
	expbits = 11,
	expbias = 1023,
	mantmask = (1 << 52) - 1,
	expmask = (1 << 11) - 1,
};

// A [[floatinfo]] structure defining the structure of the f32 type.
export const f32info: floatinfo = floatinfo {
	mantbits = 23,
	expbits = 8,
	expbias = 127,
	mantmask = (1 << 23) - 1,
	expmask = (1 << 8) - 1,
};

