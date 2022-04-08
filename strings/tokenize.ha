// License: MPL-2.0
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use bytes;
use types;

// The state for a tokenizer.
export type tokenizer = bytes::tokenizer;

// Returns a tokenizer which yields sub-strings tokenized by a delimiter.
//
// 	let tok = strings::tokenize("hello, my name is drew", " ");
// 	assert(strings::next_token(tok) as str == "hello,");
// 	assert(strings::next_token(tok) as str == "my");
// 	assert(strings::next_token(tok) as str == "name");
// 	assert(strings::remaining_tokens(tok) == "is drew");
//
// The caller must ensure that 'delimiter' is not an empty string.
export fn tokenize(s: str, delim: str) tokenizer =
	bytes::tokenize(toutf8(s), toutf8(delim));

// Returns the next string from a tokenizer, and advances the cursor. Returns
// void if there are no tokens left.
export fn next_token(s: *tokenizer) (str | void) = {
	return match (bytes::next_token(s)) {
	case let b: []u8 =>
		yield fromutf8(b);
	case void => void;
	};
};

// Same as next_token(), but does not advance the cursor
export fn peek_token(s: *tokenizer) (str | void) = {
	return match (bytes::peek_token(s)) {
	case let b: []u8 =>
		yield fromutf8(b);
	case void => void;
	};
};

// Returns the remainder of the string associated with a tokenizer, without doing
// any further tokenization.
export fn remaining_tokens(s: *tokenizer) str = {
	return fromutf8(bytes::remaining_tokens(s));
};

@test fn tokenize() void = {
	let tok = tokenize("Hello, my name is drew", " ");
	assert(next_token(&tok) as str == "Hello,");
	assert(next_token(&tok) as str == "my");
	assert(peek_token(&tok) as str == "name");
	assert(next_token(&tok) as str == "name");
	assert(remaining_tokens(&tok) == "is drew");
	assert(peek_token(&tok) as str == "is");
	assert(remaining_tokens(&tok) == "is drew");

	let tok = tokenize("foo", "foo");
	assert(peek_token(&tok) as str == "");
	assert(next_token(&tok) as str == "");
	assert(peek_token(&tok) as str == "");
	assert(next_token(&tok) as str == "");
	assert(peek_token(&tok) is void);
	assert(next_token(&tok) is void);

	let tok = tokenize("", "foo");
	assert(peek_token(&tok) is void);
	assert(next_token(&tok) is void);
};

// Splits a string into tokens delimited by 'delim', returning a slice of up to
// N tokens. The caller must free this slice. The strings within the slice are
// borrowed from 'in', and needn't be freed - but should be [[dupall]]'d if they
// should outlive 'in'.
//
// The caller must ensure that 'delimiter' is not an empty string.
export fn splitn(in: str, delim: str, n: size) []str = {
	let toks: []str = [];
	let tok = tokenize(in, delim);
	for (let i = 0z; i < n - 1z; i += 1) {
		match (next_token(&tok)) {
		case let s: str =>
			append(toks, s);
		case void =>
			return toks;
		};
	};
	append(toks, remaining_tokens(&tok));
	return toks;
};

// Splits a string into tokens delimited by 'delim'.  The caller must free the
// returned slice. The strings within the slice are borrowed from 'in', and
// needn't be freed - but must be [[dupall]]'d if they should outlive 'in'.
//
// The caller must ensure that 'delimiter' is not an empty string.
export fn split(in: str, delim: str) []str = splitn(in, delim, types::SIZE_MAX);

@test fn split() void = {
	const expected = ["Hello,", "my", "name", "is Drew"];
	const actual = splitn("Hello, my name is Drew", " ", 4z);
	assert(len(expected) == len(actual));
	for (let i = 0z; i < len(expected); i += 1) {
		assert(expected[i] == actual[i]);
	};

	const expected2 = ["Hello,", "my", "name", "is", "Drew"];
	const actual2 = split("Hello, my name is Drew", " ");
	assert(len(expected2) == len(actual2));
	for (let i = 0z; i < len(expected2); i += 1) {
		assert(expected2[i] == actual2[i]);
	};
};

// Returns a string "cut" along the first instance of a delimiter, returning
// everything up to the delimiter, and everything after the delimiter, in a
// tuple.
//
// 	strings::cut("hello=world=foobar", "=")	// ("hello", "world=foobar")
// 	strings::cut("hello world", "=")	// ("hello world", "")
//
// The return value is borrowed from the 'in' parameter.  The caller must ensure
// that 'delimiter' is not an empty string.
export fn cut(in: str, delim: str) (str, str) = {
	let c = bytes::cut(toutf8(in), toutf8(delim));
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
};
