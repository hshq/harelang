use bufio;
use io;

let static_stdin_bufio: bufio::bufstream = bufio::bufstream {
	source = 0,
	...
};

let static_stdout_bufio: bufio::bufstream = bufio::bufstream {
	source = 1,
	...
};

// The standard input. This handle is buffered.
export let stdin: io::handle = 0;

// The standard input, as an [[io::file]]. This handle is unbuffered.
export let stdin_file: io::file = 0;

// The standard output. This handle is buffered.
export let stdout: io::handle = 1;

// The standard output, as an [[io::file]]. This handle is unbuffered.
export let stdout_file: io::file = 1;

// The standard error.
export let stderr: io::file = 2;

// The recommended buffer size for reading from disk.
export def BUFSIZ: size = 4096; // 4 KiB

@init fn init_stdfd() void = {
	static let stdinbuf: [BUFSIZ]u8 = [0...];
	stdin = bufio::static_buffered(0, stdinbuf, [], &static_stdin_bufio);

	static let stdoutbuf: [BUFSIZ]u8 = [0...];
	stdout = bufio::static_buffered(1, [], stdoutbuf, &static_stdout_bufio);
};

@fini fn fini_stdfd() void = {
	// Flush any pending writes
	io::close(stdout);
};
