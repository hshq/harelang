use encoding::utf8;

const whitespace: [_]rune = [' ', '\n', '\t', '\r'];

// Returns a string (borrowed from given input string) after trimming off of
// the start of the input string the characters in the given list of runes. If
// no runes are given, returns the string with leading whitespace stripped off.
export fn ltrim(input: str, trim: rune...) str = {
	if (len(trim) == 0) {
		trim = whitespace;
	};
	let it = iter(input);
	for (true) {
		const r = match (next(&it)) {
			r: rune => r,
			void => break,
		};
		let found = false;
		for (let i = 0z; i < len(trim); i += 1) {
			if (r == trim[i]) {
				found = true;
				break;
			};
		};
		if (!found) {
			prev(&it);
			break;
		};
	};
	return fromutf8(it.dec.src[it.dec.offs..]);
};

// Returns a string (borrowed from given input string) after trimming off of
// the end of the input string the characters in the given list of runes. If no
// runes are given, returns the string with trailing whitespace stripped off.
export fn rtrim(input: str, trim: rune...) str = {
	if (len(trim) == 0) {
		trim = whitespace;
	};
	let it = riter(input);
	for (true) {
		const r = match (prev(&it)) {
			r: rune => r,
			void => break,
		};
		let found = false;
		for (let i = 0z; i < len(trim); i += 1) {
			if (r == trim[i]) {
				found = true;
				break;
			};
		};
		if (!found) {
			next(&it);
			break;
		};
	};
	return fromutf8(it.dec.src[..it.dec.offs]);
};

// Returns a string (borrowed from given input string) after trimming off of
// the both ends of the input string the characters in the given list of runes.
// If no runes are given, returns the string with both leading and trailing
// whitespace stripped off.
export fn trim(input: str, exclude: rune...) str =
	ltrim(rtrim(input, exclude...), exclude...);

@test fn trim() void = {
	assert(ltrim("") == "");
	assert(ltrim("  hi") == "hi");
	assert(ltrim("\t\r\n  hello") == "hello");
	assert(ltrim("((()(())))())", '(', ')') == "");
	assert(ltrim("abacadabra", 'a', 'b', 'c', 'd') == "ra");
	assert(ltrim("𝚊𝚋𝚊𝚌𝚊𝚍𝚊𝚋𝚛𝚊", '𝚊', '𝚋', '𝚌', '𝚍') == "𝚛𝚊");
	
	assert(rtrim("") == "");
	assert(rtrim("hello   ") == "hello");
	assert(rtrim("hello, world\r\n\r\n") == "hello, world");
	assert(rtrim("Sentimentalized sensationalism sensationalized sentimentalisms",
		' ', 's', 'i', 'l', 'z', 't', 'm', 'n', 'o', 'e', 'a', 'd') == "S");
	assert(rtrim("\\/\\/\\\\//\\//\\////\\/\\", '/', '\\') == "");
	assert(rtrim("yellowwooddoor", 'w', 'd', 'o', 'r') == "yell");

	assert(trim("") == "");
	assert(trim("    ​    ") == "​");
	assert(trim("mississippi", 'm', 'i', 'p', 's') == "");
	assert(trim("[[][[[]]][][].[[]][]]][]]]", '[', ']') == ".");
	assert(trim("AAAΑА𝖠AAAA", 'A') == "ΑА𝖠");
	assert(trim("  চিত্ত যেথা ভয়শূন্য, উচ্চ যেথা শির  ") == "চিত্ত যেথা ভয়শূন্য, উচ্চ যেথা শির");
	assert(trim("𝖺𝖻𝖺𝖼𝖺𝖽𝖺𝖻‌𝗋‌𝖺𝖼𝖺𝖽𝖺𝖻𝖼𝖺", '𝖺', '𝖻', '𝖼', '𝖽') == "‌𝗋‌");
};
