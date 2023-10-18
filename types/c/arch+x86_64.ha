// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

// Integer type compatible with `char`, as specified by ISO/IEC 9899.
export type char = schar;

// Minimum value which can be stored in a [[char]] type.
export def CHAR_MIN: char = SCHAR_MIN;

// Maximum value which can be stored in a [[char]] type.
export def CHAR_MAX: char = SCHAR_MAX;

// Integer type compatible with `signed short`, as specified by ISO/IEC 9899.
export type short = i16;

// Minimum value which can be stored in a [[short]] type.
export def SHORT_MIN: short = types::I16_MIN;

// Maximum value which can be stored in a [[short]] type.
export def SHORT_MAX: short = types::I16_MAX;

// Integer type compatible with `unsigned short`, as specified by ISO/IEC 9899.
export type ushort = u16;

// Minimum value which can be stored in a [[ushort]] type.
export def USHRT_MIN: ushort = types::U16_MIN;

// Maximum value which can be stored in a [[ushort]] type.
export def USHRT_MAX: ushort = types::U16_MAX;

// Integer type compatible with `signed long`, as specified by ISO/IEC 9899.
export type long = i64;

// Minimum value which can be stored in a [[long]] type.
export def LONG_MIN: long = types::I64_MIN;

// Maximum value which can be stored in a [[long]] type.
export def LONG_MAX: long = types::I64_MAX;

// Integer type compatible with `unsigned long`, as specified by ISO/IEC 9899.
export type ulong = u64;

// Minimum value which can be stored in a [[ulong]] type.
export def ULONG_MIN: ulong = types::U64_MIN;

// Maximum value which can be stored in a [[ulong]] type.
export def ULONG_MAX: ulong = types::U64_MAX;

// Integer type compatible with `signed long long`, as specified by ISO/IEC
// 9899:1999.
export type longlong = i64;

// Minimum value which can be stored in a [[longlong]] type.
export def LLONG_MIN: longlong = types::I64_MIN;

// Maximum value which can be stored in a [[longlong]] type.
export def LLONG_MAX: longlong = types::I64_MAX;

// Integer type compatible with `unsigned long long`, as specified by ISO/IEC
// 9899:1999.
export type ulonglong = u64;

// Minimum value which can be stored in a [[ulonglong]] type.
export def ULLONG_MIN: ulonglong = types::U64_MIN;

// Maximum value which can be stored in a [[ulonglong]] type.
export def ULLONG_MAX: ulonglong = types::U64_MAX;

// Integer type compatible with `intptr_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899.
export type intptr = i64;

// Minimum value which can be stored in an [[intptr]] type.
export def INTPTR_MIN: intptr = types::I64_MIN;

// Maximum value which can be stored in an [[intptr]] type.
export def INTPTR_MAX: intptr = types::I64_MAX;

// Integer type compatible with `ptrdiff_t`, as defined in <stddef.h> and
// specified by ISO/IEC 9899.
export type ptrdiff = i64;

// Minimum value which can be stored in a [[ptrdiff]] type.
export def PTRDIFF_MIN: ptrdiff = types::I64_MIN;

// Maximum value which can be stored in a [[ptrdiff]] type.
export def PTRDIFF_MAX: ptrdiff = types::I64_MAX;

// Integer type compatible with `ssize_t`, as defined in <sys/types.h> and
// specified by POSIX.
export type ssize = i64;

// Minimum value which can be stored in an [[ssize]] type.
export def SSIZE_MIN: ssize = types::I64_MIN;

// Maximum value which can be stored in an [[ssize]] type.
export def SSIZE_MAX: ssize = types::I64_MAX;
