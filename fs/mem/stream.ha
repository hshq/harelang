use bufio;
use errors;
use fs;
use io;
use types;

type stream = struct {
	io::stream,
	source: bufio::memstream,
	inode: *inode,
	appnd: bool,
};

fn stream_open(
	ino: *inode,
	mode: io::mode,
	appnd: bool,
) (*io::stream | fs::error) = {
	let f = ino.data as file;
	let s = alloc(stream {
		closer = &stream_close,
		seeker = &seek,
		inode = ino,
		appnd = appnd,
		...
	});
	if (mode & io::mode::WRITE == 0) {
		assert(mode & io::mode::READ == io::mode::READ);
		s.reader = &read;
		if (ino.opencount == types::SIZE_MAX) {
			return errors::busy;
		};
		ino.opencount += 1;
		s.source = bufio::fixed(f, io::mode::READ);
	} else {
		s.writer = &write;
		if (ino.opencount != 0) {
			return errors::busy;
		};
		ino.opencount = types::SIZE_MAX;
		s.source = bufio::dynamic_from(f, mode);
		if (!appnd) {
			bufio::truncate(&s.source)?;
		};
	};
	io::seek(&s.source, 0, io::whence::SET)?;
	return s;
};

fn read(s: *io::stream, buf: []u8) (size | io::EOF | io::error) = {
	return io::read(&(s: *stream).source, buf);
};

fn write(s: *io::stream, buf: const []u8) (size | io::error) = {
	let s = s: *stream;
	if (s.appnd) {
		io::seek(&s.source, 0, io::whence::END)?;
	};
	let sz = io::write(&s.source, buf)?;
	s.inode.data = bufio::buffer(&s.source);
	return sz;
};

fn seek(s: *io::stream, off: io::off, w: io::whence) (io::off | io::error) = {
	return io::seek(&(s: *stream).source, off, w);
};

fn stream_close(s: *io::stream) void = {
	let s = s: *stream;
	defer free(s);
	if (s.writer == null) {
		io::close(&s.source);
		s.inode.opencount -= 1;
		if (s.inode.opencount > 0) {
			return;
		};
	} else {
		s.inode.opencount = 0;
		io::close(&s.source);
	};

	if (s.inode.parent == null) {
		// this stream was the last reference to this file, free it
		inode_free(s.inode);
	};
};
