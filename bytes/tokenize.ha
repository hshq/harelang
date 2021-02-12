// The state for a tokenizer.
export type tokenizer = struct { s: []u8, d: []u8 };

// Returns a tokenizer which yields sub-slices tokenized by a delimiter.
export fn tokenize(s: []u8, delim: []u8) tokenizer = tokenizer {
	s = s,
	d = delim,
};

// Returns the next slice from a tokenizer, and advances the cursor. Returns
// void if there are no tokens left and on all subsequent invocations. If a
// string starts with, or ends with, a token, an empty slice is returned at the
// beginning or end of the sequence, respectively.
export fn next_token(s: *tokenizer) ([]u8 | void) = {
	if (len(s.s) == 0) {
		return;
	};

	match (index(s.s, s.d)) {
		i: size => {
			let tok = s.s[..i];
			if (len(tok) + len(s.d) == len(s.s) && len(tok) != 0) {
				s.s = s.s[i..];
			} else {
				s.s = s.s[i+len(s.d)..];
			};
			return tok;
		},
		void => {
			let tok = s.s[..];
			s.s = s.s[..0];
			return tok;
		},
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

	match (next_token(&t)) {
		b: []u8 => assert(equal([1, 2], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([3, 24], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([4, 5], b)),
		void    => abort(),
	};

	assert(next_token(&t) is void);

	const input2: [_]u8 = [24, 42, 1, 24, 42];
	t = tokenize(input2, [24, 42]);

	match (next_token(&t)) {
		b: []u8 => assert(equal([], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([1], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([], b)),
		void    => abort(),
	};

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
};
