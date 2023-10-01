// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Accepts a set of flags from [[fexcept]] ORed together and clears
// exceptions corresponding to the given flags.
export fn clearexcept(ex: fexcept) void = rt::feclearexcept(ex: uint);

// Accepts a set of flags from [[fexcept]] ORed together and raises
// exceptions corresponding to the given flags.
export fn raiseexcept(ex: fexcept) void = rt::feraiseexcept(ex: uint);

// Accepts a set of flags from [[fexcept]] ORed together and returns
// the subset that is currently raised
export fn testexcept(ex: fexcept) fexcept = rt::fetestexcept(ex: uint): fexcept;

// Returns the value corresponding to the current rounding mode
export fn getround() fround = rt::fegetround(): fround;

// Sets the rounding mode to the specified value
export fn setround(mode: fround) void = rt::fesetround(mode: uint);
