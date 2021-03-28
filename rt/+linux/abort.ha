fn platform_abort(msg: str) void = {
	const prefix = "Abort: ";
	write(2, prefix: *const char, len(prefix));
	write(2, msg: *const char, len(msg));
	write(2, "\n": *const char, 1);
	kill(getpid(), SIGABRT);
};
