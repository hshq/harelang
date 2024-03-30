// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use encoding::utf8;
use strings;

// A lexical token class.
export type ltok = enum uint {
	// Keep ordered with bmap
	// Alpha sorted

	ATTR_FINI,
	ATTR_INIT,
	ATTR_OFFSET,
	ATTR_PACKED,
	ATTR_SYMBOL,
	ATTR_TEST,
	ATTR_THREADLOCAL,
	UNDERSCORE,
	ABORT,
	ALIGN,
	ALLOC,
	APPEND,
	AS,
	ASSERT,
	BOOL,
	BREAK,
	CASE,
	CONST,
	CONTINUE,
	DEF,
	DEFER,
	DELETE,
	DONE,
	ELSE,
	ENUM,
	EXPORT,
	F32,
	F64,
	FALSE,
	FN,
	FOR,
	FREE,
	I16,
	I32,
	I64,
	I8,
	IF,
	INSERT,
	INT,
	IS,
	LEN,
	LET,
	MATCH,
	NEVER,
	NULL,
	NULLABLE,
	OFFSET,
	OPAQUE,
	RETURN,
	RUNE,
	SIZE,
	STATIC,
	STR,
	STRUCT,
	SWITCH,
	TRUE,
	TYPE,
	U16,
	U32,
	U64,
	U8,
	UINT,
	UINTPTR,
	UNION,
	USE,
	VAARG,
	VAEND,
	VALIST,
	VASTART,
	VOID,
	YIELD,
	LAST_KEYWORD = YIELD,

	// Operators

	ARROW,
	BAND,
	BANDEQ,
	BNOT,
	BOR,
	BOREQ,
	BXOR,
	BXOREQ,
	COLON,
	COMMA,
	DIV,
	DIVEQ,
	DOT,
	DOUBLE_COLON,
	DOUBLE_DOT,
	ELLIPSIS,
	EQUAL,
	GT,
	GTEQ,
	LAND,
	LANDEQ,
	LBRACE,
	LBRACKET,
	LEQUAL,
	LESS,
	LESSEQ,
	LNOT,
	LOR,
	LOREQ,
	LPAREN,
	LSHIFT,
	LSHIFTEQ,
	LXOR,
	LXOREQ,
	MINUS,
	MINUSEQ,
	MODEQ,
	MODULO,
	NEQUAL,
	PLUS,
	PLUSEQ,
	QUESTION,
	RBRACE,
	RBRACKET,
	RPAREN,
	RSHIFT,
	RSHIFTEQ,
	SEMICOLON,
	TIMES,
	TIMESEQ,
	LAST_BTOK = TIMESEQ,

	LIT_U8,
	LIT_U16,
	LIT_U32,
	LIT_U64,
	LIT_UINT,
	LIT_SIZE,
	LIT_I8,
	LIT_I16,
	LIT_I32,
	LIT_I64,
	LIT_INT,
	LIT_ICONST,
	LIT_F32,
	LIT_F64,
	LIT_FCONST,
	LIT_RCONST,
	LIT_STR,
	LAST_LITERAL = LIT_STR,

	NAME,
	EOF,
};

const bmap: [_]str = [
	// Keep ordered with tok
	"@fini",
	"@init",
	"@offset",
	"@packed",
	"@symbol",
	"@test",
	"@threadlocal",
	"_",
	"abort",
	"align",
	"alloc",
	"append",
	"as",
	"assert",
	"bool",
	"break",
	"case",
	"const",
	"continue",
	"def",
	"defer",
	"delete",
	"done",
	"else",
	"enum",
	"export",
	"f32",
	"f64",
	"false",
	"fn",
	"for",
	"free",
	"i16",
	"i32",
	"i64",
	"i8",
	"if",
	"insert",
	"int",
	"is",
	"len",
	"let",
	"match",
	"never",
	"null",
	"nullable",
	"offset",
	"opaque",
	"return",
	"rune",
	"size",
	"static",
	"str",
	"struct",
	"switch",
	"true",
	"type",
	"u16",
	"u32",
	"u64",
	"u8",
	"uint",
	"uintptr",
	"union",
	"use",
	"vaarg",
	"vaend",
	"valist",
	"vastart",
	"void",
	"yield",
	"=>",
	"&",
	"&=",
	"~",
	"|",
	"|=",
	"^",
	"^=",
	":",
	",",
	"/",
	"/=",
	".",
	"::",
	"..",
	"...",
	"=",
	">",
	">=",
	"&&",
	"&&=",
	"{",
	"[",
	"==",
	"<",
	"<=",
	"!",
	"||",
	"||=",
	"(",
	"<<",
	"<<=",
	"^^",
	"^^=",
	"-",
	"-=",
	"%=",
	"%",
	"!=",
	"+",
	"+=",
	"?",
	"}",
	"]",
	")",
	">>",
	">>=",
	";",
	"*",
	"*=",
];

static assert(len(bmap) == ltok::LAST_BTOK: size + 1);

// A token value, used for tokens such as '1337' (an integer).
export type value = (str | rune | u64 | f64 | void);

// A location within a source file.
// The path is borrowed from the file name given to the lexer.
export type location = struct {
	path: str,
	line: uint,
	col: uint
};

// A single lexical token.
export type token = (ltok, value, location);

// Converts a token to its string representation.
export fn tokstr(tok: token) const str = {
	if (tok.0 <= ltok::LAST_BTOK) {
		return bmap[tok.0: int];
	};
	switch (tok.0) {
	case ltok::LIT_U8 =>
		return "u8";
	case ltok::LIT_U16 =>
		return "u16";
	case ltok::LIT_U32 =>
		return "u32";
	case ltok::LIT_U64 =>
		return "u64";
	case ltok::LIT_UINT =>
		return "uint";
	case ltok::LIT_SIZE =>
		return "size";
	case ltok::LIT_I8 =>
		return "i8";
	case ltok::LIT_I16 =>
		return "i16";
	case ltok::LIT_I32 =>
		return "i32";
	case ltok::LIT_I64 =>
		return "i64";
	case ltok::LIT_INT =>
		return "int";
	case ltok::LIT_ICONST =>
		return "iconst";
	case ltok::LIT_F32 =>
		return "f32";
	case ltok::LIT_F64 =>
		return "f64";
	case ltok::LIT_FCONST =>
		return "fconst";
	case ltok::LIT_RCONST =>
		return "rconst";
	case ltok::LIT_STR =>
		return "str";
	case ltok::NAME =>
		return tok.1 as str;
	case ltok::EOF =>
		return "EOF";
	case =>
		abort();
	};
};
