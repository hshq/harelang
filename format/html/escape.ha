use encoding::utf8;
use io;
use strings;
use strio;

// Prints a string to an output stream, escaping any of HTML's reserved
// characters.
export fn escape(out: *io::stream, in: str) (size | io::error) = {
	let z = 0z;
	let iter = strings::iter(in);
	for (true) match (strings::next(&iter)) {
		void => break,
		rn: rune => z += io::write(out, switch (rn) {
			'&' => strings::toutf8("&amp;"),
			'<' => strings::toutf8("&lt;"),
			'>' => strings::toutf8("&gt;"),
			'"' => strings::toutf8("&quot;"),
			'\'' => strings::toutf8("&apos;"),
			*   => utf8::encoderune(rn),
		})?,
	};
	return z;
};

@test fn escape() void = {
	let sink = strio::dynamic();
	defer io::close(sink);
	escape(sink, "hello world!")!;
	assert(strio::string(sink) == "hello world!");

	let sink = strio::dynamic();
	defer io::close(sink);
	escape(sink, "\"hello world!\"")!;
	assert(strio::string(sink) == "&quot;hello world!&quot;");

	let sink = strio::dynamic();
	defer io::close(sink);
	escape(sink, "<hello & 'world'!>")!;
	assert(strio::string(sink) == "&lt;hello &amp; &apos;world&apos;!&gt;");
};
