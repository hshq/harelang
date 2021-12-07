use bytes;
use rt;
use types;

// Duplicates a string. Aborts on allocation failure.
export fn dup(s: const str) str = {
	const in = &s: *types::string;
	const id = match (in.data) {
	case null =>
		return ""; // Empty string
	case let b: *[*]u8 =>
		yield b;
	};
	let buf: *[*]u8 = match (rt::malloc(in.length + 1)) {
	case null =>
		abort("Out of memory");
	case let v: *void =>
		yield v;
	};
	buf[..in.length + 1z] = id[..in.length + 1];
	let out = types::string {
		data = buf,
		length = in.length,
		capacity = in.length,
	};
	return *(&out: *str);
};

// Creates a copy of a []str slice with all the strings duplicated. The result
// must be freed using [[freeall]].
export fn dupall(s: []str) []str = {
	let newsl = *(&types::slice {
		data = match (rt::malloc(len(s) * size(str))) {
		case null =>
			abort("Out of memory");
		case let v: *void =>
			yield v;
		},
		length = len(s),
		capacity = len(s),
	}: *[]str);

	for (let i = 0z; i < len(s); i += 1) {
		newsl[i] = strings::dup(s[i]);
	};

	return newsl;
};

// Frees all the strings in a slice and the slice itself. Inverse of [[dupall]].
export fn freeall(s: []str) void = {
	for (let i = 0z; i < len(s); i += 1) {
		free(s[i]);
	};
	free(s);
};

@test fn dup() void = {
	let s = dup("");
	assert(s == "");
	free(s);

	s = dup("hello");
	assert(s == "hello");
	free(s);
};
