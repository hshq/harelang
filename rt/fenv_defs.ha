// License: MPL-2.0
// (c) 2022 Bor Grošelj Simić <bor.groseljsimic@telemach.net>

export fn feclearexcept(ex: uint) void;
export fn feraiseexcept(ex: uint) void;
export fn fetestexcept(ex: uint) uint;

export fn fegetround() uint;
export fn fesetround(mode: uint) void;

// TODO fesetenv/fegetenv?
