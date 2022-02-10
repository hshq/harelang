export fn feclearexcept(ex: uint) void;
export fn feraiseexcept(ex: uint) void;
export fn fetestexcept(ex: uint) uint;

export fn fegetround() uint;
export fn fesetround(mode: uint) void;

// TODO fesetenv/fegetenv?
