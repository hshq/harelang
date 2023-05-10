// Integer type compatible with `char`, as specified by ISO/IEC 9899.
export type char = schar;

// Integer type compatible with `signed char`, as specified by ISO/IEC 9899.
export type schar = i8;

// Integer type compatible with `unsigned char`, as specified by ISO/IEC 9899.
export type uchar = u8;

// Integer type compatible with `signed short`, as specified by ISO/IEC 9899.
export type short = i16;

// Integer type compatible with `unsigned short`, as specified by ISO/IEC 9899.
export type ushort = u16;

// Integer type compatible with `signed long`, as specified by ISO/IEC 9899.
export type long = i64;

// Integer type compatible with `unsigned long`, as specified by ISO/IEC 9899.
export type ulong = u64;

// Integer type compatible with `signed long long`, as specified by ISO/IEC
// 9899:1999.
export type longlong = i64;

// Integer type compatible with `unsigned long long`, as specified by ISO/IEC
// 9899:1999.
export type ulonglong = u64;

// Integer type compatible with `intptr_t`, as defined in <stdint.h> and
// specified by ISO/IEC 9899.
export type intptr = i64;

// Integer type compatible with `ptrdiff_t`, as defined in <stddef.h> and
// specified by ISO/IEC 9899.
export type ptrdiff = i64;

// Integer type compatible with `ssize_t`, as defined in <sys/types.h> and
// specified by POSIX.
export type ssize = i64;
