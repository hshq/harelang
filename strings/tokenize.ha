// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use types;

export type tokenizer = bytes::tokenizer;

// Tokenizes a string, returning an iterator that yields substrings separated by
// one or more delimiters, such that the string will be split along any of the
// characters found in "delim". If the string begins with or ends with a
// delimiter, an empty string is returned respectively as the first and last
// call to [[next_token]].
//
// Each character of the delimiter string must be an ASCII character (see
// [[ascii::valid]]).
//
// The input string and delimiter string are borrowed from the caller for the
// lifetime of the tokenizer.
//
// The caller must ensure that at least one delimiter is provided and that the
// length of the input string is less than [[types::I64_MAX]].
//
// 	const tok = strings::tokenize("Hello world!\tMy name is Harriet.", " \t");
// 	assert(next_token(&tok) as str == "Hello");
// 	assert(next_token(&tok) as str == "world!");
// 	assert(next_token(&tok) as str == "My");
// 	assert(next_token(&tok) as str == "name");
// 	assert(next_token(&tok) as str == "is");
// 	assert(next_token(&tok) as str == "Harriet");
// 	assert(next_token(&tok) is done);
export fn tokenize(s: str, delim: str) tokenizer = {
	const in = toutf8(s);
	const delim = toutf8(delim);
	for (let ch .. delim) {
		assert(ch & 0x80 == 0, "strings::tokenize cannot tokenize on non-ASCII delimiters");
	};
	return bytes::tokenize(in, delim...);
};

// Like [[tokenize]], but tokenizes the string in reverse, such that the first
// call to [[next_token]] returns the last token and the last call returns the
// first token.
export fn rtokenize(s: str, delim: str) tokenizer = {
	const in = toutf8(s);
	const delim = toutf8(delim);
	for (let ch .. delim) {
		assert(ch & 0x80 == 0, "strings::tokenize cannot tokenize on non-ASCII delimiters");
	};
	return bytes::rtokenize(in, delim...);
};

// Returns the next token from a [[tokenizer]] and advances the cursor.
export fn next_token(s: *tokenizer) (str | done) = {
	let s = s: *bytes::tokenizer;
	match (bytes::next_token(s)) {
	case let b: []u8 =>
		return fromutf8_unsafe(b);
	case done => return done;
	};
};

// Returns the next token from a [[tokenizer]] without advancing the cursor.
export fn peek_token(s: *tokenizer) (str | done) = {
	let s = s: *bytes::tokenizer;
	return match (bytes::peek_token(s)) {
	case let b: []u8 =>
		yield fromutf8_unsafe(b);
	case done =>
		return done;
	};
};

// Returns the remainder of the input string from a [[tokenizer]] ahead of the
// token cursor.
export fn remaining_tokens(s: *tokenizer) str = {
	let s = s: *bytes::tokenizer;
	return fromutf8_unsafe(bytes::remaining_tokens(s));
};

fn tokenize_test(
	testcase: str,
	in: str,
	delim: str,
	tokens: []str,
	iters: size = types::SIZE_MAX,
) tokenizer = {
	const tok = tokenize(in, delim);
	let n = 0z;
	for (const want .. tokens) {
		if (n >= iters) {
			return tok;
		};
		n += 1;

		const p = peek_token(&tok) as str;
		const n = next_token(&tok) as str;
		assert(p == n, testcase);
		assert(n == want, testcase);
	};

	if (n >= iters) {
		return tok;
	};

	assert(peek_token(&tok) is done, testcase);
	assert(next_token(&tok) is done, testcase);
	return tok;
};

@test fn tokenize() void = {
	tokenize_test("simple case",
		"Hello world! My name is Harriet.", " ",
		[
			"Hello",
			"world!",
			"My",
			"name",
			"is",
			"Harriet.",
		]);

	tokenize_test("multiple delimiters",
		"/dev/sda1\t/ ext4 rw,relatime\t0 0", " \t",
		[
			"/dev/sda1",
			"/",
			"ext4",
			"rw,relatime",
			"0",
			"0",
		]);

	tokenize_test("consecutive delimiters",
		"hello    world", " ",
		[
			"hello",
			"",
			"",
			"",
			"world",
		]);

	tokenize_test("leading delimiters",
		" hello world ", " ",
		[
			"",
			"hello",
			"world",
			"",
		]);

	const tok = tokenize_test("remaining_tokens",
		"Hello world! My name is Harriet.", " ",
		[
			"Hello",
			"world!",
		], 2);
	assert(remaining_tokens(&tok) == "My name is Harriet.");
};

// Splits a string into tokens delimited by 'delim', starting at the beginning
// of the string, and returning a slice of up to N tokens. The caller must free
// this slice. The strings within the slice are borrowed from 'in'.
//
// The caller must ensure that 'delim' is not an empty string.
export fn splitn(in: str, delim: str, n: size) []str = {
	let toks: []str = [];
	let tok = tokenize(in, delim);
	for (let i = 0z; i < n - 1z; i += 1) {
		match (next_token(&tok)) {
		case let s: str =>
			append(toks, s);
		case done =>
			return toks;
		};
	};
	match(peek_token(&tok)) {
	case done => void;
	case let s: str =>
		append(toks, remaining_tokens(&tok));
	};
	return toks;
};

// Splits a string into tokens delimited by 'delim', starting at the end
// of the string, and returning a slice of up to N tokens. The caller must free
// this slice. The strings within the slice are borrowed from 'in'.
//
// The caller must ensure that 'delim' is not an empty string.
export fn rsplitn(in: str, delim: str, n: size) []str = {
	let toks: []str = [];
	let tok = rtokenize(in, delim);
	for (let i = 0z; i < n - 1z; i += 1) {
		match (next_token(&tok)) {
		case let s: str =>
			append(toks, s);
		case done =>
			return toks;
		};
	};
	match(peek_token(&tok)) {
	case done => void;
	case let s: str =>
		append(toks, remaining_tokens(&tok));
	};

	for (let i = 0z; i < len(toks) / 2; i += 1) {
		const tmp = toks[i];
		toks[i] = toks[len(toks) - i - 1];
		toks[len(toks) - i - 1] = tmp;
	};

	return toks;
};

// Splits a string into tokens delimited by 'delim'. The caller must free the
// returned slice. The strings within the slice are borrowed from 'in'.
//
// The caller must ensure that 'delim' is not an empty string.
export fn split(in: str, delim: str) []str = splitn(in, delim, types::SIZE_MAX);

@test fn split() void = {
	const expected = ["Hello,", "my", "name", "is Drew"];
	const actual = splitn("Hello, my name is Drew", " ", 4z);
	assert(len(expected) == len(actual));
	for (let i = 0z; i < len(expected); i += 1) {
		assert(expected[i] == actual[i]);
	};
	free(actual);

	const expected2 = ["Hello,", "my", "name", "is", "Drew"];
	const actual2 = split("Hello, my name is Drew", " ");
	assert(len(expected2) == len(actual2));
	for (let i = 0z; i < len(expected2); i += 1) {
		assert(expected2[i] == actual2[i]);
	};
	free(actual2);

	const expected3 = ["one"];
	const actual3 = splitn("one", "=", 2z);
	assert(len(expected3) == len(actual3));
	for (let i = 0z; i < len(expected3); i += 1) {
		assert(expected3[i] == actual3[i]);
	};
	free(actual3);

	const expected4 = ["Hello, my", "name", "is", "Drew"];
	const actual4 = rsplitn("Hello, my name is Drew", " ", 4z);
	assert(len(expected4) == len(actual4));
	for (let i = 0z; i < len(expected4); i += 1) {
		assert(expected4[i] == actual4[i]);
	};
	free(actual4);
};

// Returns a string "cut" along the first instance of a delimiter, returning
// everything up to the delimiter, and everything after the delimiter, in a
// tuple.
//
// 	strings::cut("hello=world=foobar", "=")	// ("hello", "world=foobar")
// 	strings::cut("hello world", "=")	// ("hello world", "")
//
// The return value is borrowed from the 'in' parameter. The caller must ensure
// that 'delim' is not an empty string.
export fn cut(in: str, delim: str) (str, str) = {
	let c = bytes::cut(toutf8(in), toutf8(delim));
	return (fromutf8_unsafe(c.0), fromutf8_unsafe(c.1));
};

// Returns a string "cut" along the last instance of a delimiter, returning
// everything up to the delimiter, and everything after the delimiter, in a
// tuple.
//
// 	strings::rcut("hello=world=foobar", "=")	// ("hello=world", "foobar")
// 	strings::rcut("hello world", "=")	// ("hello world", "")
//
// The return value is borrowed from the 'in' parameter. The caller must ensure
// that 'delim' is not an empty string.
export fn rcut(in: str, delim: str) (str, str) = {
	let c = bytes::rcut(toutf8(in), toutf8(delim));
	return (fromutf8_unsafe(c.0), fromutf8_unsafe(c.1));
};

@test fn cut() void = {
	const sample = cut("hello=world", "=");
	assert(sample.0 == "hello" && sample.1 == "world");
	const sample = cut("hello=world=foobar", "=");
	assert(sample.0 == "hello" && sample.1 == "world=foobar");
	const sample = cut("hello world", "=");
	assert(sample.0 == "hello world" && sample.1 == "");
	const sample = cut("", "=");
	assert(sample.0 == "" && sample.1 == "");

	const sample = rcut("hello=world=foobar", "=");
	assert(sample.0 == "hello=world" && sample.1 == "foobar");
};
