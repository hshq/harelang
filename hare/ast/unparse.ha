use fmt;
use io;
use strio;

// Unparses an identifier.
export fn ident_unparse(out: *io::stream, ident: ident) (size | io::error) = {
	let n = 0z;
	for (let i = 0z; i < len(ident); i += 1) {
		n += fmt::fprintf(out, "{}{}", ident[i],
			if (i + 1 < len(ident)) "::"
			else "")?;
	};
	return n;
};

// Unparses an identifier into a string. The caller must free the return value.
export fn ident_unparse_s(ident: ident) str = {
	let buf = strio::dynamic();
	ident_unparse(buf, ident);
	return strio::finish(buf);
};
