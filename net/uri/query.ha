// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use memio;
use strings;

export type query_decoder = struct {
	tokenizer: strings::tokenizer,
	bufs: (memio::stream, memio::stream),
};

// Initializes a decoder for a query string. Use [[query_next]] to walk it. The
// caller must call [[query_finish]] once they're done using it.
export fn decodequery(q: const str) query_decoder = query_decoder {
	tokenizer = strings::tokenize(q, "&"),
	bufs = (memio::dynamic(), memio::dynamic()),
};

// Frees resources associated with the [[query_decoder]].
export fn query_finish(dec: *query_decoder) void = {
	io::close(&dec.bufs.0)!;
	io::close(&dec.bufs.1)!;
};

// Retrieves the next (key, value) pair from the query. The return value is
// borrowed from the decoder and will be replaced on the next call, use
// [[strings::dup]] to extend its lifetime.
export fn query_next(dec: *query_decoder) ((str, str) | invalid | void) = {
	const tok = match (strings::next_token(&dec.tokenizer)) {
	case let s: str =>
		yield s;
	case => return;
	};

	const raw = strings::cut(tok, "=");
	memio::reset(&dec.bufs.0);
	percent_decode_static(&dec.bufs.0, raw.0)?;
	memio::reset(&dec.bufs.1);
	percent_decode_static(&dec.bufs.1, raw.1)?;
	return (
		memio::string(&dec.bufs.0)!,
		memio::string(&dec.bufs.1)!,
	);
};

// Encodes (key, value) pairs into a URI query string. The result must be
// freed by the caller.
export fn encodequery(pairs: [](str, str)) str = {
	const buf = memio::dynamic();
	for (let i = 0z; i < len(pairs); i += 1) {
		const pair = pairs[i];
		if (i > 0) memio::appendrune(&buf, '&')!;

		assert(len(pair.0) > 0);
		percent_encode(&buf, pair.0, unres_query_frag)!;
		if (len(pair.1) > 0) {
			memio::appendrune(&buf, '=')!;
			percent_encode(&buf, pair.1, unres_query_frag)!;
		};
	};

	return memio::string(&buf)!;
};

@test fn decodequery() void = {
	const u = parse("https://sr.ht/projects?search=%23risc-v&sort=longest-active&quantity=100%25")!;
	defer finish(&u);

	const query = decodequery(u.query);
	defer query_finish(&query);
	const pair = query_next(&query)! as (str, str);
	assert(pair.0 == "search");
	assert(pair.1 == "#risc-v");

	const pair = query_next(&query)! as (str, str);
	assert(pair.0 == "sort");
	assert(pair.1 == "longest-active");

	const pair = query_next(&query)! as (str, str);
	assert(pair.0 == "quantity");
	assert(pair.1 == "100%");
};

@test fn encodequery() void = {
	const pairs = [
		("search", "#risc-v"),
		("sort", "longest-active"),
		("quantity", "100%")
	];
	const encoded = encodequery(pairs);
	defer free(encoded);

	assert(encoded == "search=%23risc-v&sort=longest-active&quantity=100%25");
};
