// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use types;

export type tokenizer = struct {
	s: []u8, // string being tokenized
	d: []u8, // delimiter
	p: i64, // p < 0 for reverse tokenizers, 0 <= p for forward ones.
};

// Returns a tokenizer which yields sub-slices tokenized by a delimiter, starting
// at the beginning of the slice. The caller must ensure that 'delim' is not an
// empty slice. Can tokenize a slice of length less than [[types::I64_MAX]].
export fn tokenize(s: []u8, delim: []u8) tokenizer = {
	assert(len(delim) > 0, "bytes::tokenize called with empty slice");
	if (len(s) == 0) {
		delim = [];
	};
	return tokenizer {
		s = s,
		d = delim,
		p = types::I64_MAX, // I64_MAX means we haven't peeked the next token yet.
	};
};

// Returns a tokenizer which yields sub-slices tokenized by a delimiter, starting at
// the end of the slice and moving backwards with each call to [[next_token]]. The
// caller must ensure that 'delimiter' is not an empty slice. Can tokenize a slice
// of length less than [[types::I64_MAX]].
export fn rtokenize(s: []u8, delim: []u8) tokenizer = {
	assert(len(delim) > 0, "bytes::rtokenize called with empty slice");
	if (len(s) == 0) {
		delim = [];
	};
	return tokenizer {
		s = s,
		d = delim,
		p = types::I64_MIN, // I64_MIN means we haven't peeked the next token yet.
		// also note that p == -1 corresponds to an index of len(s),
		// and p == -(1 - len(s)) corresponds to an index of 0.
	};
};

// Returns the next slice from a tokenizer, and advances the cursor. Returns
// void if there are no tokens left and on all subsequent invocations. If a
// string starts with, or ends with, a token, an empty slice is returned at the
// beginning or end of the sequence, respectively.
export fn next_token(s: *tokenizer) ([]u8 | void) = {
	const b = match (peek_token(s)) {
	case let b: []u8 =>
		yield b;
	case => return;
	};

	if (s.p < 0) { // reverse
		if (len(s.s): i64 + s.p + 1 == 0) {
			s.d = s.d[..0];
			s.s = s.s[..0];
		} else {
			const end = (len(s.s): i64 + s.p + 1): size - len(s.d);
			s.s = s.s[..end];
		};
		s.p = types::I64_MIN;
	} else {
		if (s.p == len(s.s): i64) {
			s.d = s.d[..0];
			s.s = s.s[..0];
		} else {
			s.s = s.s[s.p: size + len(s.d)..];
		};
		s.p = types::I64_MAX;
	};

	return b;
};

// Same as [[next_token]], but does not advance the cursor
export fn peek_token(s: *tokenizer) ([]u8 | void) = {
	if (len(s.d) == 0) {
		return;
	};

	const reverse = s.p < 0;
	const ifunc = if (reverse) &rindex else &index;

	const known = ((s.p < 0 && s.p != types::I64_MIN) ||
		(s.p >= 0 && s.p != types::I64_MAX));
	if (!known) {
		let i = 0i64;
		let dlen = 0i64;
		let slen = len(s.s): i64;

		match (ifunc(s.s, s.d)) {
		case let ix: size =>
			dlen = len(s.d): i64;
			i = ix: i64;
		case void =>
			i = slen;
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
		return s.s[len(s.s) + s.p: size + 1..];
	} else {
		return s.s[..s.p: size];
	};
};


// Returns the remainder of the slice associated with a tokenizer, without doing
// any further tokenization.
export fn remaining_tokens(s: *tokenizer) []u8 = {
	return s.s;
};

@test fn tokenize() void = {
	const input: [_]u8 = [1, 2, 24, 42, 3, 24, 24, 42, 4, 5];
	let t = tokenize(input, [24, 42]);
	let p = peek_token(&t) as []u8;
	let n = next_token(&t) as []u8;
	assert(equal(p, n));
	assert(equal([1, 2], n));
	let p = peek_token(&t) as []u8;
	let n = next_token(&t) as []u8;
	assert(equal(p, n));
	assert(equal([3, 24], n));
	assert(equal(peek_token(&t) as []u8, peek_token(&t) as []u8));
	assert(equal([4, 5], next_token(&t) as []u8));
	assert(peek_token(&t) is void);
	assert(next_token(&t) is void);

	const input: [_]u8 = [24, 42, 1, 24, 42];
	t = tokenize(input, [24, 42]);
	assert(equal(peek_token(&t) as []u8, peek_token(&t) as []u8));
	assert(equal([], next_token(&t) as []u8));
	assert(equal(peek_token(&t) as []u8, peek_token(&t) as []u8));
	assert(equal([1], next_token(&t) as []u8));
	assert(equal(peek_token(&t) as []u8, peek_token(&t) as []u8));
	assert(equal([], next_token(&t) as []u8));
	assert(peek_token(&t) is void);
	assert(next_token(&t) is void);

	const input: [_]u8 = [1, 1, 1, 2, 1, 1, 2, 2];
	t = tokenize(input, [1, 2]);
	assert(equal([1, 1], next_token(&t) as []u8));
	assert(equal([1], next_token(&t) as []u8));
	assert(equal([2], next_token(&t) as []u8));
	assert(next_token(&t) is void);

	const input: [_]u8 = [1, 2];
	t = tokenize(input, [1, 2]);
	assert(equal([], next_token(&t) as []u8));
	assert(equal([], next_token(&t) as []u8));
	assert(peek_token(&t) is void);
	assert(next_token(&t) is void);

	const input: [_]u8 = [24, 42, 1, 24, 42, 2, 3, 4];
	t = tokenize(input, [24, 42]);
	assert(equal([], next_token(&t) as []u8));
	assert(equal([1], next_token(&t) as []u8));
	assert(equal(remaining_tokens(&t), [2, 3, 4]));
	assert(equal(peek_token(&t) as []u8, [2, 3, 4]));
	assert(equal(remaining_tokens(&t), [2, 3, 4]));

	t = tokenize([], [42]);
	assert(peek_token(&t) is void);
	assert(next_token(&t) is void);

	const input: [_]u8 = [1, 2, 24, 42, 3, 24, 24, 42, 4, 5];
	let t = rtokenize(input, [24, 42]);
	let p = peek_token(&t) as []u8;
	let n = next_token(&t) as []u8;
	assert(equal(p, n));
	assert(equal([4, 5], n));
	let p = peek_token(&t) as []u8;
	let n = next_token(&t) as []u8;
	assert(equal(p, n));
	assert(equal([3, 24], n));
	assert(equal(peek_token(&t) as []u8, peek_token(&t) as []u8));
	assert(equal([1, 2], next_token(&t) as []u8));
	assert(peek_token(&t) is void);
	assert(next_token(&t) is void);

	const input: [_]u8 = [1, 2, 3, 24, 42, 4, 24, 42];
	t = rtokenize(input, [24, 42]);
	assert(equal([], next_token(&t) as []u8));
	assert(equal([4], next_token(&t) as []u8));
	assert(equal(remaining_tokens(&t), [1, 2, 3]));
	assert(equal(peek_token(&t) as []u8, [1, 2, 3]));
	assert(equal(remaining_tokens(&t), [1, 2, 3]));
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
