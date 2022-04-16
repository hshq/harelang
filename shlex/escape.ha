use ascii;
use encoding::utf8;
use io;
use strings;
use strio;

fn is_safe(s: str) bool = {
	const iter = strings::iter(s);
	for (true) {
		const rn = match (strings::next(&iter)) {
		case let rn: rune =>
			yield rn;
		case void =>
			break;
		};


		switch (rn) {
		case '@', '%', '+', '=', ':', ',', '.', '/', '-' =>
			void;
		case =>
			if (!ascii::isalnum(rn) || ascii::isspace(rn)) {
				return false;
			};
		};
	};
	return true;
};

// Quotes a shell string and writes it to the provided I/O handle.
export fn quote(sink: io::handle, s: str) (void | io::error) = {
	if (len(s) == 0) {
		io::write(sink, strings::toutf8(`''`))?;
		return;
	};
	if (is_safe(s)) {
		io::write(sink, strings::toutf8(s))?;
		return;
	};

	io::write(sink, ['"'])?;

	const iter = strings::iter(s);
	for (true) {
		const rn = match (strings::next(&iter)) {
		case let rn: rune =>
			yield rn;
		case void =>
			break;
		};

		if (rn == '"') {
			io::write(sink, strings::toutf8(`"'"'"`))?;
		} else {
			io::write(sink, utf8::encoderune(rn))?;
		};
	};

	io::write(sink, ['"'])?;
};

// Quotes a shell string and returns a new string. The caller must free the
// return value.
export fn quotestr(s: str) str = {
	const sink = strio::dynamic();
	quote(&sink, s)!;
	return strio::string(&sink);
};
