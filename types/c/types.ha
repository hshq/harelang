use types;

// Integer type compatible with `char8_t`, as defined in <uchar.h> and specified
// by ISO/IEC 9899:2023.
export type char8 = uchar;

// Integer type compatible with `char16_t`, as defined in <uchar.h> and
// specified by ISO/IEC 9899:2011.
export type char16 = uint_least16;

// Integer type compatible with `char32_t`, as defined in <uchar.h> and
// specified by ISO/IEC 9899:2011.
export type char32 = uint_least32;

// Integer type compatible with `intmax_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
//
// Note that this type isn't necessarily the actual maximum integer type. This
// type should only be used when required for C interop.
export type intmax = i64;

// Integer type compatible with `uintmax_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
//
// Note that this type isn't necessarily the actual maximum integer type. This
// type should only be used when required for C interop.
export type uintmax = u64;

// Integer type compatible with `int_least8_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_least8 = i8;

// Integer type compatible with `int_least16_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_least16 = i16;

// Integer type compatible with `int_least32_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_least32 = i32;

// Integer type compatible with `int_least64_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_least64 = i64;

// Integer type compatible with `uint_least8_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_least8 = u8;

// Integer type compatible with `uint_least16_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_least16 = u16;

// Integer type compatible with `uint_least32_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_least32 = u32;

// Integer type compatible with `uint_least64_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_least64 = u64;

// Integer type compatible with `int_fast8_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_fast8 = i8;

// Integer type compatible with `int_fast16_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_fast16 = i16;

// Integer type compatible with `int_fast32_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_fast32 = i32;

// Integer type compatible with `int_fast64_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_fast64 = i64;

// Integer type compatible with `uint_fast8_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_fast8 = u8;

// Integer type compatible with `uint_fast16_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_fast16 = u16;

// Integer type compatible with `uint_fast32_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_fast32 = u32;

// Integer type compatible with `uint_fast64_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_fast64 = u64;

// Integer type compatible with `wchar_t`, as defined in <stddef.h> and
// specified by ISO/IEC 9899.
export type wchar = i32;

// Integer type compatible with `wint_t`, as defined in <stdint.h> and specified
// by ISO/IEC 9899:1994.
export type wint = u32;
