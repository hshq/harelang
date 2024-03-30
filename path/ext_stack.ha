// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use strings;

// Add extensions onto the end of the final path segment. The separating '.'
// will be inserted for you. If the final path segment consists entirely of dots
// or the path is root, this function will return [[cant_extend]].
export fn push_ext(buf: *buffer, exts: str...) (str | error) = {
	match (peek(buf)) {
	case void => return cant_extend;
	case let s: str => if (strings::ltrim(s, '.') == "") return cant_extend;
	};
	for (let ext .. exts) {
		const newend = buf.end + 1 + len(ext);
		if (MAX < newend) return too_long;
		buf.buf[buf.end] = '.';
		buf.buf[buf.end+1..newend] = strings::toutf8(ext);
		buf.end = newend;
	};
	return string(buf);
};

// Remove and return the final extension in a path. The result will not
// include the leading '.'. The result is borrowed from the buffer. Leading dots
// will be ignored when looking for extensions, such that ".ssh" isn't
// considered to have any extensions.
export fn pop_ext(buf: *buffer) (str | void) = {
	const ext = split_ext(buf);
	buf.end = ext.0;
	return ext.1;
};

// Examine the final extension in a path. The result will not
// include the leading '.'. The result is borrowed from the buffer. Leading dots
// will be ignored when looking for extensions, such that ".ssh" isn't
// considered to have any extensions.
export fn peek_ext(buf: *buffer) (str | void) = split_ext(buf).1;

// helper function, returns (end of non-extension, extension string)
fn split_ext(buf: *buffer) (size, (str | void)) = match (peek(buf)) {
case void => return (buf.end, void);
case let s: str =>
	const bs = strings::toutf8(s);
	bs = bytes::ltrim(bs, '.');
	match (bytes::rindex(bs, '.')) {
	case void => return (buf.end, void);
	case let i: size =>
		return (buf.end - len(bs) + i, strings::fromutf8_unsafe(bs[i+1..]));
	};
};

// Remove and return all the extensions in a path. The result will not
// include the leading '.', but will include separating dots. Leading dots
// will be ignored when looking for extensions, such that ".ssh" isn't
// considered to have any extensions. The result is borrowed from the buffer.
export fn pop_exts(buf: *buffer) (str | void) = {
	const ext = split_exts(buf);
	buf.end = ext.0;
	return ext.1;
};

// Examine all the extensions in a path. The result will not include the
// leading '.', but will include separating dots. Leading dots will
// be ignored when looking for extensions, such that ".ssh" isn't considered
// to have any extensions. The result is borrowed from the buffer.
export fn peek_exts(buf: *buffer) (str | void) = split_exts(buf).1;

// helper function, returns (end of non-extension, extension string)
fn split_exts(buf: *buffer) (size, (str | void)) = match (peek(buf)) {
case void => return (buf.end, void);
case let s: str =>
	const bs = strings::toutf8(s);
	bs = bytes::ltrim(bs, '.');
	match (bytes::index(bs, '.')) {
	case void => return (buf.end, void);
	case let i: size =>
		return (buf.end - len(bs) + i, strings::fromutf8_unsafe(bs[i+1..]));
	};
};

@test fn ext() void = {
	// push_ext
	let buf = init()!;
	assert(push_ext(&buf, "bash") is cant_extend);
	set(&buf, sepstr)!;
	assert(push_ext(&buf, "bash") is cant_extend);
	set(&buf, "....")!;
	assert(push_ext(&buf, "bash") is cant_extend);
	set(&buf, "bashrc")!;
	assert(push_ext(&buf, "bash") as str == "bashrc.bash");
	set(&buf, ".bashrc")!;
	assert(push_ext(&buf, "bash") as str == ".bashrc.bash");

	// pop_ext
	set(&buf)!;
	assert(pop_ext(&buf) is void);
	set(&buf, "..")!;
	assert(pop_ext(&buf) is void);
	set(&buf, sepstr)!;
	assert(pop_ext(&buf) is void);

	set(&buf, "index.html.tmpl")!;
	assert(pop_ext(&buf) as str == "tmpl");
	assert(string(&buf) == "index.html");
	assert(pop_ext(&buf) as str == "html");
	assert(string(&buf) == "index");
	assert(pop_ext(&buf) is void);
	assert(string(&buf) == "index");

	set(&buf, ".secret.tar.gz")!;
	assert(pop_ext(&buf) as str == "gz");
	assert(string(&buf) == ".secret.tar");
	assert(pop_ext(&buf) as str == "tar");
	assert(string(&buf) == ".secret");
	assert(pop_ext(&buf) is void);
	assert(string(&buf) == ".secret");

	set(&buf, "..ext")!;
	assert(pop_ext(&buf) is void);
	assert(string(&buf) == "..ext");

	// pop_exts
	set(&buf, "index.html.tmpl")!;
	assert(pop_exts(&buf) as str == "html.tmpl");
	assert(string(&buf) == "index");
	assert(pop_exts(&buf) is void);
	assert(string(&buf) == "index");

	set(&buf, ".secret.tar.gz")!;
	assert(pop_exts(&buf) as str == "tar.gz");
	assert(string(&buf) == ".secret");
	assert(pop_ext(&buf) is void);
	assert(string(&buf) == ".secret");
};
