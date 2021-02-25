use rt;

// TEMP: This is due to be rewritten to be less shit
export fn println(msgs: str...) void = {
	for (let i = 0z; i < len(msgs); i += 1) {
		let msg = msgs[i];
		rt::write(1, msg: *const char, len(msg));
		if (i + 1 < len(msgs)) {
			rt::write(1, " ": *const char, 1);
		};
	};
	rt::write(1, "\n": *const char, 1);
};

export fn errorln(msgs: str...) void = {
	for (let i = 0z; i < len(msgs); i += 1) {
		let msg = msgs[i];
		rt::write(2, msg: *const char, len(msg));
		if (i + 1 < len(msgs)) {
			rt::write(2, " ": *const char, 1);
		};
	};
	rt::write(2, "\n": *const char, 1);
};
