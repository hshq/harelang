@test fn split() void = {
	const s = split("hello\\ world")!;
	defer splitfree(s);
	assert(len(s) == 1);
	assert(s[0] == "hello world");

	const s = split("'hello\\ world'")!;
	defer splitfree(s);
	assert(len(s) == 1);
	assert(s[0] == "hello\\ world");

	const s = split("\"hello\\\\world\"")!;
	defer splitfree(s);
	assert(len(s) == 1);
	assert(s[0] == "hello\\world");

	const s = split("\"hello \"'\"'\"world\"'\"'")!;
	defer splitfree(s);
	assert(len(s) == 1);
	assert(s[0] == "hello \"world\"");

	const s = split("hello '' world")!;
	defer splitfree(s);
	assert(len(s) == 3);
	assert(s[0] == "hello");
	assert(s[1] == "");
	assert(s[2] == "world");

	const s = split("with\\ backslashes 'single quoted' \"double quoted\"")!;
	defer splitfree(s);
	assert(len(s) == 3);
	assert(s[0] == "with backslashes");
	assert(s[1] == "single quoted");
	assert(s[2] == "double quoted");

	const s = split("'multiple spaces'      42")!;
	defer splitfree(s);
	assert(len(s) == 2);
	assert(s[0] == "multiple spaces");
	assert(s[1] == "42");

	// Invalid
	assert(split("\"dangling double quote") is syntaxerr);
	assert(split("'dangling single quote") is syntaxerr);
	assert(split("unterminated\\ backslash \\") is syntaxerr);
};
