use io;
use bufio;
use strings;

@test fn basic() void = {
	xmltest("<?xml version='1.0' encoding='utf-8' ?>
<root>
	<hello name='foobar'>world</hello>
	<foobar bar='foobaz' />
</root>", [
		"root": elementstart,
		"\n\t": text,
		"hello": elementstart,
		("name", "foobar"): attribute,
		"world": text,
		"hello": elementend,
		"\n\t": text,
		"foobar": elementstart,
		("bar", "foobaz"): attribute,
		"foobar": elementend,
		"\n": text,
		"root": elementend,
	], false);
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
		"hello": elementend,
		"\n": text,
		"root": elementend,
	], false);
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
		"hello": elementend,
		"\n": text,
		"root": elementend,
	], false);
};

@test fn cdata() void = {
	xmltest("<?xml version='1.0' encoding='utf-8' ?>
<root>
	<![CDATA[Hello world &foo <bar>]]>
</root>", [
		"root": elementstart,
		"\n\t": text,
		"Hello world &foo <bar>": text,
		"\n": text,
		"root": elementend,
	], false);
};

@test fn errors() void = {
	xmltest("<?xml version='1.0' encoding='utf-8' ?>
<root>
	<hello name='foobar'></world>
</root>", [
		"root": elementstart,
		"\n\t": text,
		"hello": elementstart,
		("name", "foobar"): attribute,
	], true);
};

fn xmltest(input: str, expected: []token, error: bool) void = {
	let in = bufio::fixed(strings::toutf8(input), io::mode::READ);
	defer io::close(in);
	let parser = parse(in) as *parser;
	for (let i = 0z; i < len(expected); i += 1) {
		let tok = match (scan(parser)) {
		case tok: token =>
			yield tok;
		case void =>
			abort("Expected token, got void");
		case syntaxerr =>
			abort("Expected token, got syntax error");
		};
		match (tok) {
		case el: elementstart =>
			let ex = expected[i] as elementstart;
			assert(el == ex);
		case at: attribute =>
			let ex = expected[i] as attribute;
			assert(at.0 == ex.0 && at.1 == ex.1);
		case tx: text =>
			let ex = expected[i] as text;
			assert(tx == ex);
		case el: elementend =>
			let ex = expected[i] as elementend;
			assert(el == ex);
		};
	};
	if (error) {
		assert(scan(parser) is error);
	} else {
		assert(scan(parser) is void);
	};
};
