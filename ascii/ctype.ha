def U: u8 = 0o1u8;
def L: u8 = 0o2u8;
def N: u8 = 0o4u8;
def S: u8 = 0o10u8;
def P: u8 = 0o20u8;
def C: u8 = 0o40u8;
def B: u8 = 0o100u8;
def X: u8 = 0o200u8;

// LUT of bitfields with character attributes
const cclass: []u8 = [
//	 0	 1	 2	 3	 4	 5	 6	 7
	C,	C,	C,	C,	C,	C,	C,	C,	// 0
	C,	S|C,	S|C,	S|C,	S|C,	S|C,	C,	C,	// 10
	C,	C,	C,	C,	C,	C,	C,	C,	// 20
	C,	C,	C,	C,	C,	C,	C,	C,	// 30
	S|B,	P,	P,	P,	P,	P,	P,	P,	// 40
	P,	P,	P,	P,	P,	P,	P,	P,	// 50
	N|X,	N|X,	N|X,	N|X,	N|X,	N|X,	N|X,	N|X,	// 60
	N|X,	N|X,	P,	P,	P,	P,	P,	P,	// 70
	P,	U|X,	U|X,	U|X,	U|X,	U|X,	U|X,	U,	// 100
	U,	U,	U,	U,	U,	U,	U,	U,	// 110
	U,	U,	U,	U,	U,	U,	U,	U,	// 120
	U,	U,	U,	P,	P,	P,	P,	P,	// 130
	P,	L|X,	L|X,	L|X,	L|X,	L|X,	L|X,	L,	// 140
	L,	L,	L,	L,	L,	L,	L,	L,	// 150
	L,	L,	L,	L,	L,	L,	L,	L,	// 160
	L,	L,	L,	P,	P,	P,	P,	C,	// 170
];

// True if an ASCII character is a letter
export fn isalpha(c: u8) bool = cclass[c]&(U|L) > 0u8;

// True if an ASCII character is uppercase
export fn isupper(c: u8) bool = cclass[c]&U > 0u8;

// True if an ASCII character is lowercase
export fn islower(c: u8) bool = cclass[c]&L > 0u8;

// True if an ASCII character is a digit
export fn isdigit(c: u8) bool = cclass[c]&N > 0u8;

// True if an ASCII character is a hexadecimal digit
export fn isxdigit(c: u8) bool = cclass[c]&X > 0u8;

// True if an ASCII character is a space.
export fn isspace(c: u8) bool = cclass[c]&S > 0u8;

// True if an ASCII character is punctuation.
export fn ispunct(c: u8) bool = cclass[c]&P > 0u8;

// True if an ASCII character is alphanumeric.
export fn isalnum(c: u8) bool = cclass[c]&(U|L|N) > 0u8;

// True if an ASCII character is printable.
export fn isprint(c: u8) bool = cclass[c]&(P|U|L|N|B) > 0u8;

// True if an ASCII character is any printable character other than space.
export fn isgraph(c: u8) bool = cclass[c]&(P|U|L|N) > 0u8;

// True if an ASCII character is a control character.
export fn iscntrl(c: u8) bool = cclass[c]&C > 0u8;

// True if a u8 is a valid ASCII character.
export fn isascii(c: u8) bool = c <= 0o177u8;

// Returns the uppercase form of an ASCII character, or the original character
// if it was not a lowercase letter.
export fn toupper(c: u8) u8 = {
	return if (islower(c)) c - ('a': u32: u8) + ('A': u32: u8) else c;
};

// Returns the lowercase form of an ASCII character, or the original character
// if it was not an uppercase letter.
export fn tolower(c: u8) u8 = {
	return if (isupper(c)) c - ('A': u32: u8) + ('a': u32: u8) else c;
};

// Converts a u8 to ASCII by truncating the most significant bit.
export fn toascii(c: u8) u8 = c & 0o177u8;
