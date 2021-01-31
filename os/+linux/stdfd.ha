use io;

@init fn init_stdfd() void = {
	// TODO: use static_fdopen for these
	stdin = fdopen(0, "<stdin>");
	stdout = fdopen(1, "<stdout>");
	stderr = fdopen(2, "<stderr>");
};
