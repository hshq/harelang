use rt;

// TEMP: This is due to be thrown out and rewritten to be not shit
export fn println(msg: str) void = {
	rt::write(1, msg: *const char, len(msg));
	rt::write(1, "\n": *const char, 1z);
};
