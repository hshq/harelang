// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
// (c) 2022 Humm <hummsmith42@gmail.com>
use bytes;
use errors;
use strings;

export type buffer = struct {
	buf: [PATH_MAX]u8,
	end: size,
};

// Initializes a new path buffer.
export fn init(items: str...) (buffer | errors::overflow) = {
	let buf = buffer { ... };
	push(&buf, items...)?;
	return buf;
};

// Sets the value of a path buffer to a list of components, overwriting any
// previous value. Returns the new string value of the path.
export fn set(buf: *buffer, items: str...) (str | errors::overflow) = {
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
