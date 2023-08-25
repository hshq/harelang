// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
// (c) 2022 Humm <hummsmith42@gmail.com>
use bytes;
use strings;

export type buffer = struct {
	buf: [MAX]u8,
	end: size,
};

// Initializes a new path buffer.
export fn init(items: str...) (buffer | error) = {
	let buf = buffer { ... };
	push(&buf, items...)?;
	return buf;
};

// Sets the value of a path buffer to a list of components, overwriting any
// previous value. Returns the new string value of the path.
export fn set(buf: *buffer, items: str...) (str | error) = {
	buf.end = 0;
	return push(buf, items...);
};

// Returns the current path stored in this buffer. 
// The return value is borrowed from the buffer. Use [[strings::dup]] to
// extend the lifetime of the string.
export fn string(buf: *buffer) str = {
	if (buf.end == 0) return ".";
	return strings::fromutf8_unsafe(buf.buf[..buf.end]);
};

// Check if a path is an absolute path.
export fn abs(path: (*buffer | str)) bool = match (path) {
case let path: str => return strings::hasprefix(path, sepstr);
case let buf: *buffer => return 0 < buf.end && buf.buf[0] == SEP;
};

// Check if a path is the root directory.
export fn isroot(path: (*buffer | str)) bool = match (path) {
case let path: str => return path == sepstr;
case let buf: *buffer => return buf.end == 1 && buf.buf[0] == SEP;
};

// Replace '/' with system-dependent path separator in a string. Modifies the
// original string, but is idempotent. The result is borrowed from the input.
export fn local(path: str) str = {
	let bs = strings::toutf8(path);
	for (let k = 0z; k < len(bs); k += 1) {
		if (bs[k] == '/') bs[k] = SEP;
	};
	return path;
};
