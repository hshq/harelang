// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

export type tokenizer = struct {
	in: []u8,	// string being tokenized
	delim: []u8,	// delimiter
	p: i64,		// p < 0 for reverse tokenizers, 0 <= p for forward ones.
};

// Tokenizes a byte slice, returning an iterator that yields tokens from the
// slice delimited by one of any number of delimiter bytes. If the input slice
// begins with or ends with a delimiter, an empty slice is returned respectively
// as the first and last call to [[next_token]].
//
// The variadic argument slice is borrowed from the caller, who should take care
// to ensure that it is valid for the lifetime of the tokenizer.
//
// The caller must ensure that at least one delimiter is provided and that the
// length of the slice is less than [[types::I64_MAX]].
export fn tokenize(in: []u8, delim: u8...) tokenizer = {
	assert(len(delim) > 0, "bytes::tokenize called with empty slice");
	assert(len(in) < types::I64_MAX: size,
		"bytes::tokenize: input length exceeds I64_MAX");
	if (len(in) == 0) {
		delim = [];
	};

	return tokenizer {
		in = in,
		delim = delim,
		p = types::I64_MAX, // I64_MAX means we haven't peeked the next token yet.
	};
};

// Like [[tokenize]], but tokenizes the slice in reverse, such that the first
// call to [[next_token]] returns the last token and the last call returns the
// first token.
export fn rtokenize(in: []u8, delim: u8...) tokenizer = {
	assert(len(delim) > 0, "bytes::rtokenize called with empty slice");
	assert(len(in) < types::I64_MAX: size,
		"bytes::rtokenize: input length exceeds I64_MAX");
	if (len(in) == 0) {
		delim = [];
	};

	return tokenizer {
		in = in,
		delim = delim,
		// I64_MIN means we haven't peeked the next token yet. Note that
		// p == -1 corresponds to an index of len(s), and
		// p == -(1 - len(s)) corresponds to an index of 0.
		p = types::I64_MIN,
	};
};

// Returns the next token from a [[tokenizer]] and advances the cursor.
export fn next_token(s: *tokenizer) ([]u8 | done) = {
	const b = match (peek_token(s)) {
	case let b: []u8 =>
		yield b;
	case done => return done;
	};

	const slen = len(s.in): i64;
	const reverse = s.p < 0;
	if (reverse) {
		if (slen + s.p + 1 == 0) {
			s.delim = s.delim[..0];
			s.in = s.in[..0];
		} else {
			const end = (slen + s.p + 1): size - 1;
			s.in = s.in[..end];
		};
		s.p = types::I64_MIN;
	} else {
		if (s.p == slen) {
			s.delim = s.delim[..0];
			s.in = s.in[..0];
		} else {
			s.in = s.in[s.p: size + 1..];
		};
		s.p = types::I64_MAX;
	};

	return b;
};

// Returns the next token from a [[tokenizer]] without advancing the cursor.
export fn peek_token(s: *tokenizer) ([]u8 | done) = {
	if (len(s.delim) == 0) {
		return done;
	};

	const reverse = s.p < 0;
	const ifunc = if (reverse) &rindex else &index;

	const known = ((reverse && s.p != types::I64_MIN) ||
		(!reverse && s.p != types::I64_MAX));
	if (!known) {
		let i = if (reverse) types::I64_MIN else types::I64_MAX;
		let dlen = 0i64;
		const slen = len(s.in): i64;

		for (let d .. s.delim) {
			match (ifunc(s.in, d)) {
			case let ix: size =>
				if (!reverse && ix: i64 < i) {
					i = ix: i64;
					dlen = 1;
				} else if (reverse && ix: i64 > i) {
					i = ix: i64;
					dlen = 1;
				};
			case void =>
				if (!reverse && slen < i: i64) {
					i = slen;
				} else if (reverse && 0 > i: i64) {
					i = 0;
				};
			};
		};

		if (reverse) {
			if (i == slen) {
				s.p = -(slen + 1);
			} else {
				s.p = i + dlen - slen - 1;
			};
		} else {
			s.p = i;
		};
	};

	if (reverse) {
		return s.in[len(s.in) + s.p: size + 1..];
	} else {
		return s.in[..s.p: size];
	};
};

// Returns the remainder of the input slice from a [[tokenizer]] ahead of the
// token cursor.
export fn remaining_tokens(s: *tokenizer) []u8 = {
	return s.in;
};

fn tokenize_test(
	func: *fn([]u8, u8...) tokenizer,
	testcase: str,
	in: []u8,
	delim: []u8,
	tokens: [][]u8,
	iters: size = types::SIZE_MAX,
) tokenizer = {
	const tok = func(in, delim...);
	let n = 0z;
	for (const want .. tokens) {
		if (n >= iters) {
			return tok;
		};
		n += 1;

		const p = peek_token(&tok) as []u8;
		const n = next_token(&tok) as []u8;
		assert(equal(p, n), testcase);
		assert(equal(n, want), testcase);
	};

	if (n >= iters) {
		return tok;
	};

	assert(peek_token(&tok) is done, testcase);
	assert(next_token(&tok) is done, testcase);
	return tok;
};

@test fn tokenize() void = {
	tokenize_test(&tokenize, "simple case", [1, 2, 0, 3, 4], [0], [
		[1, 2],
		[3, 4],
	]);

	tokenize_test(&tokenize, "multiple delimiters", [1, 2, 0, 3, 4, 42, 5, 6], [0, 42], [
		[1, 2],
		[3, 4],
		[5, 6],
	]);

	tokenize_test(&tokenize, "empty tokens", [1, 2, 0, 0, 0, 3, 4], [0], [
		[1, 2],
		[],
		[],
		[3, 4],
	]);

	tokenize_test(&tokenize, "leading empty tokens", [0, 1, 2, 3, 0], [0], [
		[],
		[1, 2, 3],
		[],
	]);

	const tok = tokenize_test(&tokenize, "remaining_tokens", [1, 2, 0, 3, 4], [0], [
		[1, 2],
	], 1);
	assert(equal(remaining_tokens(&tok), [3, 4]));
};

@test fn rtokenize() void = {
	tokenize_test(&rtokenize, "simple case", [1, 2, 0, 3, 4], [0], [
		[3, 4],
		[1, 2],
	]);

	tokenize_test(&rtokenize, "multiple delimiters", [1, 2, 0, 3, 4, 42, 5, 6], [0, 42], [
		[5, 6],
		[3, 4],
		[1, 2],
	]);

	tokenize_test(&rtokenize, "empty tokens", [1, 2, 0, 0, 0, 3, 4], [0], [
		[3, 4],
		[],
		[],
		[1, 2],
	]);

	tokenize_test(&rtokenize, "leading empty tokens", [0, 1, 2, 3, 0], [0], [
		[],
		[1, 2, 3],
		[],
	]);

	const tok = tokenize_test(&rtokenize, "remaining_tokens", [1, 2, 0, 3, 4], [0], [
		[3, 4],
	], 1);
	assert(equal(remaining_tokens(&tok), [1, 2]));
};

// Returns the input slice "cut" along the first instance of a delimiter,
// returning everything up to the delimiter, and everything after the delimiter,
// in a tuple. The contents are borrowed from the input slice.
//
// The caller must ensure that 'delimiter' is not an empty slice.
export fn cut(in: []u8, delim: ([]u8 | u8)) ([]u8, []u8) = {
	let ln = if (delim is u8) {
		yield 1z;
	} else {
		let ln = len(delim: []u8);
		assert(ln > 0, "bytes::cut called with empty delimiter");
		yield ln;
	};
	match (index(in, delim)) {
	case let i: size =>
		return (in[..i], in[i + ln..]);
	case void =>
		return (in, []);
	};
};

// Returns the input slice "cut" along the last instance of a delimiter,
// returning everything up to the delimiter, and everything after the delimiter,
// in a tuple. The contents are borrowed from the input slice.
//
// The caller must ensure that 'delimiter' is not an empty slice.
export fn rcut(in: []u8, delim: ([]u8 | u8)) ([]u8, []u8) = {
	let ln = if (delim is u8) {
		yield 1z;
	} else {
		let ln = len(delim: []u8);
		assert(ln > 0, "bytes::rcut called with empty delimiter");
		yield ln;
	};
	match (rindex(in, delim)) {
	case let i: size =>
		return (in[..i], in[i + ln..]);
	case void =>
		return (in, []);
	};
};

@test fn cut() void = {
	const c = cut(['a', 'b', 'c'], ['b']);
	assert(equal(c.0, ['a']) && equal(c.1, ['c']));
	const c = cut(['a', 'b', 'c'], 'b');
	assert(equal(c.0, ['a']) && equal(c.1, ['c']));
	const c = cut(['a', 'b', 'c', 'b', 'a'], 'b');
	assert(equal(c.0, ['a']) && equal(c.1, ['c', 'b', 'a']));
	const c = cut(['a', 'b', 'c'], 'x');
	assert(equal(c.0, ['a', 'b', 'c']) && equal(c.1, []));
	const c = cut([], 'x');
	assert(equal(c.0, []) && equal(c.1, []));

	const c = rcut(['a', 'b', 'c'], ['b']);
	assert(equal(c.0, ['a']) && equal(c.1, ['c']));
	const c = rcut(['a', 'b', 'c', 'b', 'a'], 'b');
	assert(equal(c.0, ['a', 'b', 'c']) && equal(c.1, ['a']));
};
