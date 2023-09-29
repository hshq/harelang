// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// A big integer is stored in an array of words. The first word holds
// information about the effective size of the big integer. The subsequend
// words encode the value in little-endian order. The [[WORD_BITMASK]] masks the
// bits that are actually used to store the value in each word.
export type word = u32;

// Number of bits that are used for storing the value in a word.
export def WORD_BITSZ: u32 = 31;

// Bitmask for bits that are used for storing the value in a word.
export def WORD_BITMASK: word = 0x7fffffff;

// full_bitlen(word) == 1 << WORD_SHIFT
def WORD_SHIFT: u32 = 5;
