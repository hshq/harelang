// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use io;
use rt;

let stdin_bufio: bufio::stream = bufio::stream {
	// Will be overwritten, but must be initialized
	stream = null: io::stream,
	source = 0,
	...
};

let stdout_bufio: bufio::stream = bufio::stream {
	// Will be overwritten, but must be initialized
	stream = null: io::stream,
	source = 1,
	...
};

// The standard input. This handle is buffered.
export let stdin: io::handle = rt::STDIN_FILENO; // initialized by init_stdfd

// The standard input, as an [[io::file]]. This handle is unbuffered.
export let stdin_file: io::file = rt::STDIN_FILENO;

// The standard output. This handle is buffered.
export let stdout: io::handle = rt::STDOUT_FILENO; // initialized by init_stdfd

// The standard output, as an [[io::file]]. This handle is unbuffered.
export let stdout_file: io::file = rt::STDOUT_FILENO;

// The standard error. This handle is unbuffered.
export let stderr: io::handle = rt::STDERR_FILENO;

// The standard error, as an [[io::file]]. This handle is unbuffered.
export let stderr_file: io::file = rt::STDERR_FILENO;

// The recommended buffer size for reading from disk.
export def BUFSZ: size = 4096; // 4 KiB

@init fn init_stdfd() void = {
	static let stdinbuf: [BUFSZ]u8 = [0...];
	stdin_bufio = bufio::init(stdin_file, stdinbuf, []);
	stdin = &stdin_bufio;

	static let stdoutbuf: [BUFSZ]u8 = [0...];
	stdout_bufio = bufio::init(stdout_file, [], stdoutbuf);
	stdout = &stdout_bufio;
};

@fini fn fini_stdfd() void = {
	// Flush any pending writes
	io::close(stdout): void;
};
