use rt;

// TEMP: This is due to be rewritten to be less shit
export fn println(msg: str) void = {
	rt::write(1, msg: *const char, len(msg));
	rt::write(1, "\n": *const char, 1);
};

export fn errorln(msg: str) void = {
	rt::write(2, msg: *const char, len(msg));
	rt::write(2, "\n": *const char, 1);
};
