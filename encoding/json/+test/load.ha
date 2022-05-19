use bufio;
use io;
use strings;

@test fn load() void = {
	const input = `1234`;
	const reader = bufio::fixed(strings::toutf8(input), io::mode::READ);
	const val = load(&reader)!;
	defer finish(val);
	assert(val as f64 == 1234.0);

	const input = `[]`;
	const reader = bufio::fixed(strings::toutf8(input), io::mode::READ);
	const val = load(&reader)!;
	defer finish(val);
	assert(len(val as []value) == 0);

	const input = `[1, 2, 3, null]`;
	const reader = bufio::fixed(strings::toutf8(input), io::mode::READ);
	const val = load(&reader)!;
	defer finish(val);
	const vals = val as []value;
	assert(vals[0] as f64 == 1.0);
	assert(vals[1] as f64 == 2.0);
	assert(vals[2] as f64 == 3.0);
	assert(vals[3] is _null);

	const input = `{}`;
	const reader = bufio::fixed(strings::toutf8(input), io::mode::READ);
	const val = load(&reader)!;
	defer finish(val);
	assert(val is object);

	const input = `{ "hello": "world", "answer": 42 }`;
	const reader = bufio::fixed(strings::toutf8(input), io::mode::READ);
	const val = load(&reader)!;
	defer finish(val);
	assert(val is object);
	const obj = val as object;
	assert(*(get(&obj, "hello") as *value) as str == "world");
	assert(*(get(&obj, "answer") as *value) as f64 == 42.0);
};

@test fn nestlimit() void = {
	const input = `{ "foo": [[[{"bar": ["baz"]}]]] }`;
	const reader = bufio::fixed(strings::toutf8(input), io::mode::READ);
	const val = load(&reader, 6: nestlimit)!;
	finish(val);
	io::seek(&reader, 0, io::whence::SET)!;
	assert(load(&reader, 5: nestlimit) is limitreached);
};
