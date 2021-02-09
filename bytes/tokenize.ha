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
	if (len(s.s) == 0z) {
		return void;
	};

	match (index(s.s, s.d)) {
		i: size => {
			let tok = s.s[..i];
			if (len(tok) + len(s.d) == len(s.s) && len(tok) != 0z) {
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
	const input = [1u8, 2u8, 24u8, 42u8, 3u8, 24u8, 24u8, 42u8, 4u8, 5u8];
	let t = tokenize(input, [24u8, 42u8]);

	match (next_token(&t)) {
		b: []u8 => assert(equal([1u8, 2u8], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([3u8, 24u8], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([4u8, 5u8], b)),
		void    => abort(),
	};

	assert(next_token(&t) is void);

	const input2 = [24u8, 42u8, 1u8, 24u8, 42u8];
	t = tokenize(input2, [24u8, 42u8]);

	match (next_token(&t)) {
		b: []u8 => assert(equal([], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([1u8], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([], b)),
		void    => abort(),
	};

	assert(next_token(&t) is void);

	const input3 = [1u8, 1u8, 1u8, 2u8, 1u8, 1u8, 2u8, 2u8];
	t = tokenize(input3, [1u8, 2u8]);

	match (next_token(&t)) {
		b: []u8 => assert(equal([1u8, 1u8], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([1u8], b)),
		void    => abort(),
	};

	match (next_token(&t)) {
		b: []u8 => assert(equal([2u8], b)),
		void    => abort(),
	};

	assert(next_token(&t) is void);
};
