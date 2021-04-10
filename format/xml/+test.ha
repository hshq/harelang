use io;
use bufio;
use strings;

use fmt;

@test fn basic() void = {
	xmltest("<?xml version='1.0' encoding='utf-8' ?>
<root>
	<hello name='foobar'>world</hello>
</root>", [
		"root": elementstart,
		"\n\t": text,
		"hello": elementstart,
		("name", "foobar"): attribute,
		"world": text,
		elementend,
		"\n": text,
		elementend,
	]);
};

@test fn comments() void = {
	xmltest("<?xml version='1.0' encoding='utf-8' ?>
<!-- hello -- world -->
<root>
	<hello name='foobar'>world<!----></hello>
</root>", [
		"root": elementstart,
		"\n\t": text,
		"hello": elementstart,
		("name", "foobar"): attribute,
		"world": text,
		elementend,
		"\n": text,
		elementend,
	]);
};

@test fn entities() void = {
	xmltest("<?xml version='1.0' encoding='utf-8' ?>
<root>
	<hello name='foobar &amp;&#33;&#x21;'>&lt;world&gt; &quot;&apos;</hello>
</root>", [
		"root": elementstart,
		"\n\t": text,
		"hello": elementstart,
		("name", "foobar &!!"): attribute,
		"<world> \"'": text,
		elementend,
		"\n": text,
		elementend,
	]);
};

fn xmltest(input: str, expected: []token) void = {
	let in = bufio::fixed(strings::toutf8(input), io::mode::READ);
	defer io::close(in);
	let parser = parse(in) as *parser;
	for (let i = 0z; i < len(expected); i += 1) {
		let tok = match (scan(parser)) {
			tok: token => tok,
			void => abort("Expected token, got void"),
			syntaxerr => abort("Expected token, got syntax error"),
		};
		match (tok) {
			el: elementstart => {
				let ex = expected[i] as elementstart;
				assert(el == ex);
			},
			at: attribute => {
				let ex = expected[i] as attribute;
				fmt::errorfln("want: '{}'='{}', got: '{}'='{}'",
					ex.0, ex.1, at.0, at.1);
				assert(at.0 == ex.0 && at.1 == ex.1);
			},
			tx: text => {
				let ex = expected[i] as text;
				assert(tx == ex);
			},
			elementend => assert(expected[i] is elementend),
		};
	};
	assert(scan(parser) is void);
};
