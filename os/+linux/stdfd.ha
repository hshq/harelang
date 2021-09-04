use bufio;
use io;

let static_stdin_fd: fdstream  = fdstream { ... };
let static_stdout_fd: fdstream = fdstream { ... };
let static_stderr_fd: fdstream = fdstream { ... };

let static_stdin_bufio: bufio::bufstream  = bufio::bufstream { ... };
let static_stdout_bufio: bufio::bufstream = bufio::bufstream { ... };

// The recommended buffer size for reading from disk.
export def BUFSIZ: size = 4096; // 4 KiB

@init fn init_stdfd() void = {
	static_stdin_fd = fdopen(0, "<stdin>", io::mode::READ);
	static_stdout_fd = fdopen(1, "<stdout>", io::mode::WRITE);
	static_stderr_fd = fdopen(2, "<stderr>", io::mode::WRITE);
	stdin = &static_stdin_fd;
	stdout = &static_stdout_fd;
	stderr = &static_stderr_fd;

	static let stdinbuf: [BUFSIZ]u8 = [0...];
	stdin = bufio::static_buffered(stdin, stdinbuf, [], &static_stdin_bufio);

	static let stdoutbuf: [BUFSIZ]u8 = [0...];
	stdout = bufio::static_buffered(stdout, [], stdoutbuf, &static_stdout_bufio);
};

@fini fn fini_stdfd() void = {
	// Flush any pending writes
	io::close(stdout);
};
