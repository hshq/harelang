// License: MPL-2.0
// (c) 2021-2022 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
use errors;

// A stream is a pointer to a [[vtable]] which allows for user-defined I/O
// abstractions to implement some subset of read, write, seek, close, and other
// I/O functionality in userspace.
export type stream = *vtable;

// The vtable type defines a set of virtual functions for a [[stream]]. To
// create a custom stream type, embed
//
//	export type my_stream = struct {
//		vtable: io::vtable,
//		fd: int,
//	};
//
//	const my_vtable: io::vtable = io::vtable {
//		reader = &my_stream_read,
//		writer = &my_stream_write,
//		closer = null,
//		...
//	};
//
//	export fn open(path: str) my_stream = {
//		let fd = // ...
//		return my_stream {
//			vtable = &my_vtable,
//			fd = fd,
//			...
//		});
//	};
//
//	let stream = open("example");
//	io::read(&stream, buf)!;
export type vtable = struct {
	reader: nullable *reader,
	writer: nullable *writer,
	closer: nullable *closer,
	seeker: nullable *seeker,
	copier: nullable *copier,
};

fn st_read(s: *stream, buf: []u8) (size | EOF | error) = {
	match (s.reader) {
	case null =>
		return errors::unsupported;
	case let r: *reader =>
		return r(s, buf);
	};
};

fn st_write(s: *stream, buf: const []u8) (size | error) = {
	match (s.writer) {
	case null =>
		return errors::unsupported;
	case let w: *writer =>
		return w(s, buf);
	};
};

fn st_close(s: *stream) void = {
	match (s.closer) {
	case null => void;
	case let c: *closer =>
		c(s);
	};
};

fn st_seek(s: *stream, off: off, w: whence) (off | error) = {
	match (s.seeker) {
	case null =>
		return errors::unsupported;
	case let sk: *seeker =>
		return sk(s, off, w);
	};
};
