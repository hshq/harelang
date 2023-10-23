// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

// Integer type compatible with `signed char`, as specified by ISO/IEC 9899.
export type schar = i8;

// Minimum value which can be stored in an [[schar]] type.
export def SCHAR_MIN: schar = types::I8_MIN;

// Maximum value which can be stored in an [[schar]] type.
export def SCHAR_MAX: schar = types::I8_MAX;

// Integer type compatible with `unsigned char`, as specified by ISO/IEC 9899.
export type uchar = u8;

// Minimum value which can be stored in a [[uchar]] type.
export def UCHAR_MIN: uchar = types::U8_MIN;

// Maximum value which can be stored in a [[uchar]] type.
export def UCHAR_MAX: uchar = types::U8_MAX;

// Integer type compatible with `char8_t`, as defined in <uchar.h> and specified
// by ISO/IEC 9899:2023.
export type char8 = uchar;

// Minimum value which can be stored in a [[char8]] type.
export def CHAR8_MIN: char8 = UCHAR_MIN;

// Maximum value which can be stored in a [[char8]] type.
export def CHAR8_MAX: char8 = UCHAR_MAX;

// Integer type compatible with `char16_t`, as defined in <uchar.h> and
// specified by ISO/IEC 9899:2011.
export type char16 = uint_least16;

// Minimum value which can be stored in a [[char16]] type.
export def CHAR16_MIN: char16 = UINT_LEAST16_MIN;

// Maximum value which can be stored in a [[char16]] type.
export def CHAR16_MAX: char16 = UINT_LEAST16_MAX;

// Integer type compatible with `char32_t`, as defined in <uchar.h> and
// specified by ISO/IEC 9899:2011.
export type char32 = uint_least32;

// Minimum value which can be stored in a [[char32]] type.
export def CHAR32_MIN: char32 = UINT_LEAST32_MIN;

// Maximum value which can be stored in a [[char32]] type.
export def CHAR32_MAX: char32 = UINT_LEAST32_MAX;

// Integer type compatible with `intmax_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
//
// Note that this type isn't necessarily the actual maximum integer type. This
// type should only be used when required for C interop.
export type intmax = i64;

// Minimum value which can be stored in an [[intmax]] type.
export def INTMAX_MIN: intmax = types::I64_MIN;

// Maximum value which can be stored in an [[intmax]] type.
export def INTMAX_MAX: intmax = types::I64_MAX;

// Integer type compatible with `uintmax_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
//
// Note that this type isn't necessarily the actual maximum integer type. This
// type should only be used when required for C interop.
export type uintmax = u64;

// Minimum value which can be stored in a [[uintmax]] type.
export def UINTMAX_MIN: uintmax = types::U64_MIN;

// Maximum value which can be stored in a [[uintmax]] type.
export def UINTMAX_MAX: uintmax = types::U64_MAX;

// Integer type compatible with `int_least8_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_least8 = i8;

// Minimum value which can be stored in an [[int_least8]] type.
export def INT_LEAST8_MIN: int_least8 = types::I8_MIN;

// Maximum value which can be stored in an [[int_least8]] type.
export def INT_LEAST8_MAX: int_least8 = types::I8_MAX;

// Integer type compatible with `int_least16_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_least16 = i16;

// Minimum value which can be stored in an [[int_least16]] type.
export def INT_LEAST16_MIN: int_least16 = types::I16_MIN;

// Maximum value which can be stored in an [[int_least16]] type.
export def INT_LEAST16_MAX: int_least16 = types::I16_MAX;

// Integer type compatible with `int_least32_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_least32 = i32;

// Minimum value which can be stored in an [[int_least32]] type.
export def INT_LEAST32_MIN: int_least32 = types::I32_MIN;

// Maximum value which can be stored in an [[int_least32]] type.
export def INT_LEAST32_MAX: int_least32 = types::I32_MAX;

// Integer type compatible with `int_least64_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_least64 = i64;

// Minimum value which can be stored in an [[int_least64]] type.
export def INT_LEAST64_MIN: int_least64 = types::I64_MIN;

// Maximum value which can be stored in an [[int_least64]] type.
export def INT_LEAST64_MAX: int_least64 = types::I64_MAX;

// Integer type compatible with `uint_least8_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_least8 = u8;

// Minimum value which can be stored in a [[uint_least8]] type.
export def UINT_LEAST8_MIN: uint_least8 = types::U8_MIN;

// Maximum value which can be stored in a [[uint_least8]] type.
export def UINT_LEAST8_MAX: uint_least8 = types::U8_MAX;

// Integer type compatible with `uint_least16_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_least16 = u16;

// Minimum value which can be stored in a [[uint_least16]] type.
export def UINT_LEAST16_MIN: uint_least16 = types::U16_MIN;

// Maximum value which can be stored in a [[uint_least16]] type.
export def UINT_LEAST16_MAX: uint_least16 = types::U16_MAX;

// Integer type compatible with `uint_least32_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_least32 = u32;

// Minimum value which can be stored in a [[uint_least32]] type.
export def UINT_LEAST32_MIN: uint_least32 = types::U32_MIN;

// Maximum value which can be stored in a [[uint_least32]] type.
export def UINT_LEAST32_MAX: uint_least32 = types::U32_MAX;

// Integer type compatible with `uint_least64_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_least64 = u64;

// Minimum value which can be stored in a [[uint_least64]] type.
export def UINT_LEAST64_MIN: uint_least64 = types::U64_MIN;

// Maximum value which can be stored in a [[uint_least64]] type.
export def UINT_LEAST64_MAX: uint_least64 = types::U64_MAX;

// Integer type compatible with `int_fast8_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_fast8 = i8;

// Minimum value which can be stored in an [[int_fast8]] type.
export def INT_FAST8_MIN: int_fast8 = types::I8_MIN;

// Maximum value which can be stored in an [[int_fast8]] type.
export def INT_FAST8_MAX: int_fast8 = types::I8_MAX;

// Integer type compatible with `int_fast16_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_fast16 = i16;

// Minimum value which can be stored in an [[int_fast16]] type.
export def INT_FAST16_MIN: int_fast16 = types::I16_MIN;

// Maximum value which can be stored in an [[int_fast16]] type.
export def INT_FAST16_MAX: int_fast16 = types::I16_MAX;

// Integer type compatible with `int_fast32_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_fast32 = i32;

// Minimum value which can be stored in an [[int_fast32]] type.
export def INT_FAST32_MIN: int_fast32 = types::I32_MIN;

// Maximum value which can be stored in an [[int_fast32]] type.
export def INT_FAST32_MAX: int_fast32 = types::I32_MAX;

// Integer type compatible with `int_fast64_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type int_fast64 = i64;

// Minimum value which can be stored in an [[int_fast64]] type.
export def INT_FAST64_MIN: int_fast64 = types::I64_MIN;

// Maximum value which can be stored in an [[int_fast64]] type.
export def INT_FAST64_MAX: int_fast64 = types::I64_MAX;

// Integer type compatible with `uint_fast8_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_fast8 = u8;

// Minimum value which can be stored in a [[uint_fast8]] type.
export def UINT_FAST8_MIN: uint_fast8 = types::U8_MIN;

// Maximum value which can be stored in a [[uint_fast8]] type.
export def UINT_FAST8_MAX: uint_fast8 = types::U8_MAX;

// Integer type compatible with `uint_fast16_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_fast16 = u16;

// Minimum value which can be stored in a [[uint_fast16]] type.
export def UINT_FAST16_MIN: uint_fast16 = types::U16_MIN;

// Maximum value which can be stored in a [[uint_fast16]] type.
export def UINT_FAST16_MAX: uint_fast16 = types::U16_MAX;

// Integer type compatible with `uint_fast32_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_fast32 = u32;

// Minimum value which can be stored in a [[uint_fast32]] type.
export def UINT_FAST32_MIN: uint_fast32 = types::U32_MIN;

// Maximum value which can be stored in a [[uint_fast32]] type.
export def UINT_FAST32_MAX: uint_fast32 = types::U32_MAX;

// Integer type compatible with `uint_fast64_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899:1999.
export type uint_fast64 = u64;

// Minimum value which can be stored in a [[uint_fast64]] type.
export def UINT_FAST64_MIN: uint_fast64 = types::U64_MIN;

// Maximum value which can be stored in a [[uint_fast64]] type.
export def UINT_FAST64_MAX: uint_fast64 = types::U64_MAX;

// Integer type compatible with `wchar_t`, as defined in <stddef.h> and
// specified by ISO/IEC 9899.
export type wchar = i32;

// Minimum value which can be stored in a [[wchar]] type.
export def WCHAR_MIN: wchar = types::I32_MIN;

// Maximum value which can be stored in a [[wchar]] type.
export def WCHAR_MAX: wchar = types::I32_MAX;

// Integer type compatible with `wint_t`, as defined in <stdint.h> and specified
// by ISO/IEC 9899:1994.
export type wint = u32;

// Minimum value which can be stored in a [[wint]] type.
export def WINT_MIN: wint = types::U32_MIN;

// Maximum value which can be stored in a [[wint]] type.
export def WINT_MAX: wint = types::U32_MAX;
