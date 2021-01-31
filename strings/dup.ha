use bytes;
use rt;
use types;

// Duplicates a string. Aborts on allocation failure.
export fn dup(s: const str) str = {
	let in = &s: *types::string;
	let buf: *[*]u8 = match (rt::malloc(in.length + 1z)) {
		null => abort("Out of memory"),
		v: *void => v: *[*]u8,
	};
	bytes::copy(buf[..in.length + 1z], in.data[..in.length + 1z]);
	let out = types::string {
		data     = buf,
		length   = in.length,
		capacity = in.length,
	};
	return *(&out: *str);
};
