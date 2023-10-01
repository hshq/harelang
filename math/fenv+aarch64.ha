// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Defines flags characterizing types of floating point exceptions,
// Each of the flags is only defined when the target platform supports handling
// the corresponding exception. Flags NONE and ALL are always
// defined and correspond to a bitwise OR of none and all defined flags
// respectively. Platforms may define additional nonstandard flags.
//
// Examples:
// 	math::raiseexcept(math::fexcept::UNDERFLOW); // raise UNDERFLOW
// 	math::clearexcept(math::fexcept::ALL); // clear all exceptions
//
// 	// e will be math::fexcept::INVALID
// 	math::clearexcept(math::fexcept::ALL);
// 	let a = 0.0/0.0;
// 	let e = math::testexcept(math::fexcept::INVALID | math::fexcept::INEXACT);
export type fexcept = enum uint {
	// No flags set
	NONE = 0,
	// Occurs when there is no well-defined result of an operation, such as
	// with 0/0 or sqrt(-1)
	INVALID = 1 << 0,
	// Occurs when an operation on finite numbers produces infinity
	DIVBYZERO = 1 << 1,
	// Occurs when the result of an operation is much bigger (by
	// absolute value) than the biggest representable finite number
	OVERFLOW = 1 << 2,
	// Occurs when the result of an operation is too small (by
	// absolute value) to be stored as a normalized number
	UNDERFLOW = 1 << 3,
	// Occurs when the result of an operation is rounded to a
	// value that differs from the infinite precision result.
	INEXACT = 1 << 4,
	// Combination of all flags
	ALL = INVALID | DIVBYZERO | OVERFLOW | UNDERFLOW | INEXACT,
};

// Defines values characterizing different floating point rounding behaviors.
// Each of the values is only definined when the target platform supports the
// corresponding rounding mode.
export type fround = enum uint {
	// Round towards nearest integer, with ties rounding to even
	TONEAREST = 0,
	// Round towards negative infinity
	DOWNWARD = 0x800000,
	// Round towards positive infinity
	UPWARD = 0x400000,
	// Round towards zero
	TOWARDZERO = 0xC00000,
};

@test fn fexcept() void = {
	assert(testexcept(fexcept::ALL) == fexcept::NONE);
	assert(testexcept(fexcept::NONE) == fexcept::NONE);

	raiseexcept(fexcept::INEXACT | fexcept::DIVBYZERO);

	assert(testexcept(fexcept::INEXACT) == fexcept::INEXACT);
	assert(testexcept(fexcept::DIVBYZERO) == fexcept::DIVBYZERO);
	assert(testexcept(fexcept::UNDERFLOW) == fexcept::NONE);
	assert(testexcept(fexcept::DIVBYZERO | fexcept::INEXACT)
				== fexcept::DIVBYZERO | fexcept::INEXACT);
	assert(testexcept(fexcept::DIVBYZERO | fexcept::INEXACT | fexcept::INVALID)
				== fexcept::DIVBYZERO | fexcept::INEXACT);

	clearexcept(fexcept::INEXACT);

	assert(testexcept(fexcept::DIVBYZERO | fexcept::INEXACT) == fexcept::DIVBYZERO);

	raiseexcept(fexcept::ALL);

	assert(testexcept(fexcept::ALL) == fexcept::ALL);
	assert(testexcept(fexcept::NONE) == fexcept::NONE);

	clearexcept(fexcept::ALL);

	assert(testexcept(fexcept::ALL) == fexcept::NONE);
	assert(testexcept(fexcept::NONE) == fexcept::NONE);
};

@test fn fround() void = {
	// from musl's testsuite
	let f = &f64frombits;

	assert(getround() == fround::TONEAREST);
	assert(isnan(nearbyintf64(f(0x7ff8000000000000))));
	assert(nearbyintf64(f(0x7ff0000000000000)) == INF);
	assert(nearbyintf64(f(0xfff0000000000000)) == -INF);
	assert(nearbyintf64(f(0x0)) == f(0x0));
	assert(nearbyintf64(f(0x8000000000000000)) == f(0x8000000000000000));
	assert(nearbyintf64(f(0x3ff0000000000000)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbff0000000000000)) == f(0xbff0000000000000));
	assert(nearbyintf64(f(0x3fe0000000000000)) == f(0x0));
	assert(nearbyintf64(f(0xbfe0000000000000)) == f(0x8000000000000000));
	assert(nearbyintf64(f(0x3ff0001000000000)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbff0001000000000)) == f(0xbff0000000000000));
	assert(nearbyintf64(f(0x3feffff000000000)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbfeffff000000000)) == f(0xbff0000000000000));
	assert(nearbyintf64(f(0x39b0000000000000)) == f(0x0));
	assert(nearbyintf64(f(0xb9b0000000000000)) == f(0x8000000000000000));

	setround(fround::DOWNWARD);
	assert(getround() == fround::DOWNWARD);
	assert(isnan(nearbyintf64(f(0x7ff8000000000000))));
	assert(nearbyintf64(f(0x7ff0000000000000)) == INF);
	assert(nearbyintf64(f(0xfff0000000000000)) == -INF);
	assert(nearbyintf64(f(0x0)) == f(0x0));
	assert(nearbyintf64(f(0x8000000000000000)) == f(0x8000000000000000));
	assert(nearbyintf64(f(0x3ff0000000000000)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbff0000000000000)) == f(0xbff0000000000000));
	assert(nearbyintf64(f(0x3fe0000000000000)) == f(0x0));
	assert(nearbyintf64(f(0xbfe0000000000000)) == f(0xbff0000000000000));
	assert(nearbyintf64(f(0x3ff0001000000000)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbff0001000000000)) == f(0xc000000000000000));
	assert(nearbyintf64(f(0x3feffff000000000)) == f(0x0));
	assert(nearbyintf64(f(0xbfeffff000000000)) == f(0xbff0000000000000));
	assert(nearbyintf64(f(0x39b0000000000000)) == f(0x0));
	assert(nearbyintf64(f(0xb9b0000000000000)) == f(0xbff0000000000000));

	setround(fround::UPWARD);
	assert(getround() == fround::UPWARD);
	assert(isnan(nearbyintf64(f(0x7ff8000000000000))));
	assert(nearbyintf64(f(0x7ff0000000000000)) == INF);
	assert(nearbyintf64(f(0xfff0000000000000)) == -INF);
	assert(nearbyintf64(f(0x0)) == f(0x0));
	assert(nearbyintf64(f(0x8000000000000000)) == f(0x8000000000000000));
	assert(nearbyintf64(f(0x3ff0000000000000)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbff0000000000000)) == f(0xbff0000000000000));
	assert(nearbyintf64(f(0x3fe0000000000000)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbfe0000000000000)) == f(0x8000000000000000));
	assert(nearbyintf64(f(0x3ff0001000000000)) == f(0x4000000000000000));
	assert(nearbyintf64(f(0xbff0001000000000)) == f(0xbff0000000000000));
	assert(nearbyintf64(f(0x3feffff000000000)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xbfeffff000000000)) == f(0x8000000000000000));
	assert(nearbyintf64(f(0x39b0000000000000)) == f(0x3ff0000000000000));
	assert(nearbyintf64(f(0xb9b0000000000000)) == f(0x8000000000000000));

	let f = &f32frombits;

	setround(fround::TONEAREST);
	assert(getround() == fround::TONEAREST);
	assert(isnan(nearbyintf32(f(0x7fc00000))));
	assert(nearbyintf32(f(0x7f800000)) == INF);
	assert(nearbyintf32(f(0xff800000)) == -INF);
	assert(nearbyintf32(f(0x0)) == f(0x0));
	assert(nearbyintf32(f(0x80000000)) == f(0x80000000));
	assert(nearbyintf32(f(0x3f800000)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbf800000)) == f(0xbf800000));
	assert(nearbyintf32(f(0x3f000000)) == f(0x0));
	assert(nearbyintf32(f(0xbf000000)) == f(0x80000000));
	assert(nearbyintf32(f(0x3f800080)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbf800080)) == f(0xbf800000));
	assert(nearbyintf32(f(0x3f7fff80)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbf7fff80)) == f(0xbf800000));
	assert(nearbyintf32(f(0xd800000)) == f(0x0));
	assert(nearbyintf32(f(0x8d800000)) == f(0x80000000));

	setround(fround::DOWNWARD);
	assert(getround() == fround::DOWNWARD);
	assert(isnan(nearbyintf32(f(0x7fc00000))));
	assert(nearbyintf32(f(0x7f800000)) == INF);
	assert(nearbyintf32(f(0xff800000)) == -INF);
	assert(nearbyintf32(f(0x0)) == f(0x0));
	assert(nearbyintf32(f(0x80000000)) == f(0x80000000));
	assert(nearbyintf32(f(0x3f800000)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbf800000)) == f(0xbf800000));
	assert(nearbyintf32(f(0x3f000000)) == f(0x0));
	assert(nearbyintf32(f(0xbf000000)) == f(0xbf800000));
	assert(nearbyintf32(f(0x3f800080)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbf800080)) == f(0xc0000000));
	assert(nearbyintf32(f(0x3f7fff80)) == f(0x0));
	assert(nearbyintf32(f(0xbf7fff80)) == f(0xbf800000));
	assert(nearbyintf32(f(0xd800000)) == f(0x0));
	assert(nearbyintf32(f(0x8d800000)) == f(0xbf800000));

	setround(fround::UPWARD);
	assert(getround() == fround::UPWARD);
	assert(isnan(nearbyintf32(f(0x7fc00000))));
	assert(nearbyintf32(f(0x7f800000)) == INF);
	assert(nearbyintf32(f(0xff800000)) == -INF);
	assert(nearbyintf32(f(0x0)) == f(0x0));
	assert(nearbyintf32(f(0x80000000)) == f(0x80000000));
	assert(nearbyintf32(f(0x3f800000)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbf800000)) == f(0xbf800000));
	assert(nearbyintf32(f(0x3f000000)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbf000000)) == f(0x80000000));
	assert(nearbyintf32(f(0x3f800080)) == f(0x40000000));
	assert(nearbyintf32(f(0xbf800080)) == f(0xbf800000));
	assert(nearbyintf32(f(0x3f7fff80)) == f(0x3f800000));
	assert(nearbyintf32(f(0xbf7fff80)) == f(0x80000000));
	assert(nearbyintf32(f(0xd800000)) == f(0x3f800000));
	assert(nearbyintf32(f(0x8d800000)) == f(0x80000000));
};
