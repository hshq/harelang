const _empty: stream = stream {
	reader = &empty_read,
	writer = &empty_write,
	...
};

// A [[stream]] which always reads EOF and discards any writes.
export const empty: *stream = &_empty;

fn empty_read(s: *stream, buf: []u8) (size | EOF | error) = EOF;

fn empty_write(s: *stream, buf: const []u8) (size | error) = len(buf);
