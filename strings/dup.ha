use bytes;
use rt;
use types;

// Duplicates a string. Aborts on allocation failure.
export fn dup(s: const str) str = {
	let in = &s: *types::string;
	let buf: *[*]u8 = match (rt::malloc(in.length + 1)) {
		null => abort("Out of memory"),
		v: *void => v,
	};
	bytes::copy(buf[..in.length + 1z], in.data[..in.length + 1]);
	let out = types::string {
		data     = buf,
		length   = in.length,
		capacity = in.length,
	};
	return *(&out: *str);
};

// Duplicates every string of a slice in place, returning the same slice with
// new strings.
export fn dup_all(s: []str) void = {
	for (let i = 0z; i < len(s); i += 1) {
		s[i] = strings::dup(s[i]);
	};
};
