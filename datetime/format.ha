use errors;
use fmt;
use io;
use strings;
use strio;

// Parses a string into a [[datetime]]
export fn strptime(format: str, s: str, dt: *datetime) (void | errors::invalid) = {
	// TODO
	return void;
};

// Formats a [[datetime]] and writes it into a caller supplied buffer.
// The returned string is borrowed from this buffer.
// Fails if a particular datetime field is required but void.
export fn bstrftime(buf: []u8, format: str, dt: *datetime) (str | errors::invalid | io::error) = {
	let sink = strio::fixed(buf);
	defer io::close(sink);
	fmttime(sink, format, dt)?;
	return strio::string(sink);
};

// Formats a [[datetime]] and writes it into a heap-allocated string.
// The caller must free the return value.
// Fails if a particular datetime field is required but void.
export fn strftime(format: str, dt: *datetime) (str | errors::invalid | io::error) = {
	let sink = strio::dynamic();
	fmttime(sink, format, dt)?;
	return strio::finish(sink);
};

// Formats a [[datetime]] and writes it into a [[io::handle]].
// Fails a particular field is required but void.
export fn fmttime(h: io::handle, format: str, dt: *datetime) (size | errors::invalid | io::error) = {
	// TODO
	return 0z;
};
