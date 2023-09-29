// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Minimum value which can be stored in an i8 type.
export def I8_MIN: i8 = -128;

// Maximum value which can be stored in an i8 type.
export def I8_MAX: i8 = 127;

// Minimum value which can be stored in an i16 type.
export def I16_MIN: i16 = -32768;

// Maximum value which can be stored in an i16 type.
export def I16_MAX: i16 = 32767;

// Minimum value which can be stored in an i32 type.
export def I32_MIN: i32 = -2147483648;

// Maximum value which can be stored in an i32 type.
export def I32_MAX: i32 = 2147483647;

// Minimum value which can be stored in an i64 type
export def I64_MIN: i64 = -9223372036854775808i64;

// Maximum value which can be stored in an i64 type.
export def I64_MAX: i64 = 9223372036854775807;


// Minimum value which can be stored in a u8 type.
export def U8_MIN: u8 = 0;

// Maximum value which can be stored in a u8 type.
export def U8_MAX: u8 = 255;

// Minimum value which can be stored in a u16 type
export def U16_MIN: u16 = 0;

// Maximum value which can be stored in a u16 type.
export def U16_MAX: u16 = 65535;

// Minimum value which can be stored in a u32 type
export def U32_MIN: u32 = 0;

// Maximum value which can be stored in a u32 type.
export def U32_MAX: u32 = 4294967295;

// Minimum value which can be stored in a u64 type
export def U64_MIN: u64 = 0;

// Maximum value which can be stored in a u64 type.
export def U64_MAX: u64 = 18446744073709551615;

// Minimum Unicode codepoint which can be stored in a rune.
export def RUNE_MIN: rune = '\0';

// Maximum Unicode codepoint which can be stored in a rune.
export def RUNE_MAX: rune = '\U0010ffff';
