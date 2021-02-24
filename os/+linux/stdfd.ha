use io;

let static_stdin: fd_stream  = fd_stream { ... };
let static_stdout: fd_stream = fd_stream { ... };
let static_stderr: fd_stream = fd_stream { ... };

@init fn init_stdfd() void = {
	stdin = static_fdopen(0, "<stdin>", io::mode::READ, &static_stdin);
	stdout = static_fdopen(1, "<stdout>", io::mode::WRITE, &static_stdout);
	stderr = static_fdopen(2, "<stderr>", io::mode::WRITE, &static_stderr);
};
