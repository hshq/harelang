use types;

// The state for a tokenizer.
export type tokenizer = struct { s: []u8, d: []u8, p: size };

// Returns a tokenizer which yields sub-slices tokenized by a delimiter.
// Caller should ensure delim is not an empty slice
export fn tokenize(s: []u8, delim: []u8) tokenizer = {
	assert(len(delim) > 0);
	if (len(s) == 0) {
		delim = [];
	};
	return tokenizer {
		s = s,
		d = delim,
		p = types::SIZE_MAX,
	};
};

// Returns the next slice from a tokenizer, and advances the cursor. Returns
// void if there are no tokens left and on all subsequent invocations. If a
// string starts with, or ends with, a token, an empty slice is returned at the
// beginning or end of the sequence, respectively.
export fn next_token(s: *tokenizer) ([]u8 | void) = match (peek_token(s)) {
	b: []u8 => {
		if (s.p == len(s.s)) {
			s.d = s.d[..0];
			s.s = s.s[..0];
		} else {
			s.s = s.s[s.p + len(s.d)..];
		};
		s.p = types::SIZE_MAX;
		return b;
	},
	void => void,
};

// Same as next_token(), but does not advance the cursor
export fn peek_token(s: *tokenizer) ([]u8 | void) = {
	if (len(s.d) == 0) {
		return;
	};
	if (s.p > len(s.s)) {
		s.p = match (index(s.s, s.d)) {
			i: size => i,
			void => len(s.s),
		};
	};
	return s.s[..s.p];
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

	p = peek_token(&t) as []u8;
	n = next_token(&t) as []u8;
	assert(equal(p, n));
	assert(equal([3, 24], n));

	assert(equal(peek_token(&t) as []u8, peek_token(&t) as []u8));
	match (next_token(&t)) {
		b: []u8 => assert(equal([4, 5], b)),
		void    => abort(),
	};

	assert(peek_token(&t) is void);
	assert(next_token(&t) is void);

	const input2: [_]u8 = [24, 42, 1, 24, 42];
	t = tokenize(input2, [24, 42]);

	assert(equal(peek_token(&t) as []u8, peek_token(&t) as []u8));
	match (next_token(&t)) {
		b: []u8 => assert(equal([], b)),
		void    => abort(),
	};

	assert(equal(peek_token(&t) as []u8, peek_token(&t) as []u8));
	match (next_token(&t)) {
		b: []u8 => assert(equal([1], b)),
		void    => abort(),
	};

	//assert(equal(peek_token(&t) as []u8, peek_token(&t) as []u8));
	//assert(false);
	match (next_token(&t)) {
		b: []u8 => assert(equal([], b)),
		void    => abort(),
	};

	assert(peek_token(&t) is void);
	assert(next_token(&t) is void);

	const input3: [_]u8 = [1, 1, 1, 2, 1, 1, 2, 2];
	t = tokenize(input3, [1, 2]);

	match (next_token(&t)) {
		b: []u8 => assert(equal([1, 1], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([1], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([2], b)),
		void    => abort(),
	};

	assert(next_token(&t) is void);

	const input4: [_]u8 = [1, 2];
	t = tokenize(input4, [1, 2]);

	match (next_token(&t)) {
		b: []u8 => assert(equal([], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([], b)),
		void    => abort(),
	};

	assert(peek_token(&t) is void);
	assert(next_token(&t) is void);

	const input5: [_]u8 = [24, 42, 1, 24, 42, 2, 3, 4];
	t = tokenize(input5, [24, 42]);

	match (next_token(&t)) {
		b: []u8 => assert(equal([], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([1], b)),
		void    => abort(),
	};

	assert(equal(remaining_tokens(&t), [2, 3, 4]));
	assert(equal(peek_token(&t) as []u8, [2, 3, 4]));
	assert(equal(remaining_tokens(&t), [2, 3, 4]));

	t = tokenize([]: []u8, [42]);
	assert(peek_token(&t) is void);
	assert(next_token(&t) is void);
};
