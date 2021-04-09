use io;
use bufio;
use strings;

@test fn basic() void = {
	const input = "<?xml version='1.0' encoding='utf-8' ?>
<root>
	<hello name='foobar'>world</hello>
</root>";
	const expected: []token = [
		"root": elementstart,
		"\n\t": text,
		"hello": elementstart,
		("name", "foobar"): attribute,
		"world": text,
		elementend,
		"\n": text,
		elementend,
	];
	let in = bufio::fixed(strings::toutf8(input), io::mode::READ);
	defer io::close(in);
	let parser = parse(in) as *parser;
	for (let i = 0z; i < len(expected); i += 1) {
		let tok = scan(parser) as token;
		match (tok) {
			el: elementstart => {
				let ex = expected[i] as elementstart;
				assert(el == ex);
			},
			at: attribute => {
				let ex = expected[i] as attribute;
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
