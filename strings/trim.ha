// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;

const whitespace: [_]u8 = [' ', '\n', '\t', '\r'];

// Returns a string (borrowed from given input string) after trimming off of
// the start of the input string the characters in the given list of runes. If
// no runes are given, returns the string with leading whitespace stripped off.
export fn ltrim(input: str, trim: rune...) str = {
	if (len(trim) == 0) {
		let input = toutf8(input);
		return fromutf8_unsafe(bytes::ltrim(input, whitespace...));
	};
	let it = iter(input);
	for :outer (let r => next(&it)) {
		for (let tr .. trim) {
			if (r == tr) {
				continue :outer;
			};
		};
		prev(&it);
		break;
	};
	return fromutf8_unsafe(it.dec.src[it.dec.offs..]);
};

// Returns a string (borrowed from given input string) after trimming off of
// the end of the input string the characters in the given list of runes. If no
// runes are given, returns the string with trailing whitespace stripped off.
export fn rtrim(input: str, trim: rune...) str = {
	if (len(trim) == 0) {
		let input = toutf8(input);
		return fromutf8_unsafe(bytes::rtrim(input, whitespace...));
	};
	let it = riter(input);
	for :outer (let r => next(&it)) {
		for (let tr .. trim) {
			if (r == tr) {
				continue :outer;
			};
		};
		prev(&it);
		break;
	};
	return fromutf8_unsafe(it.dec.src[..it.dec.offs]);
};

// Returns a string (borrowed from given input string) after trimming off of
// the both ends of the input string the characters in the given list of runes.
// If no runes are given, returns the string with both leading and trailing
// whitespace stripped off.
export fn trim(input: str, exclude: rune...) str =
	ltrim(rtrim(input, exclude...), exclude...);

// Returns a string (borrowed from given input string) after trimming off the
// given prefix. If the input string doesn't have the given prefix, it is
// returned unmodified.
export fn trimprefix(input: str, trim: str) str = {
	if (!hasprefix(input, trim)) return input;
	const slice = toutf8(input);
	return fromutf8_unsafe(slice[len(trim)..]);
};

// Returns a string (borrowed from given input string) after trimming off the
// given suffix. If the input string doesn't have the given suffix, it is
// returned unmodified.
export fn trimsuffix(input: str, trim: str) str = {
	if (!hassuffix(input, trim)) return input;
	const slice = toutf8(input);
	return fromutf8_unsafe(slice[..len(input) - len(trim)]);
};

@test fn trim() void = {
	assert(ltrim("") == "");
	assert(ltrim("  hi") == "hi");
	assert(ltrim("\t\r\n  hello") == "hello");
	assert(ltrim("((()(())))())", '(', ')') == "");
	assert(ltrim("abacadabra", 'a', 'b', 'c', 'd') == "ra");
	assert(ltrim("𝚊𝚋𝚊𝚌𝚊𝚍𝚊𝚋𝚛𝚊", '𝚊', '𝚋', '𝚌', '𝚍') == "𝚛𝚊"); // '𝚊' = U+1D68A

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

	assert(trimprefix("", "") == "");
	assert(trimprefix("", "blablabla") == "");
	assert(trimprefix("hello, world", "hello") == ", world");
	assert(trimprefix("blablabla", "bla") == "blabla");

	assert(trimsuffix("", "") == "");
	assert(trimsuffix("", "blablabla") == "");
	assert(trimsuffix("hello, world", "world") == "hello, ");
	assert(trimsuffix("blablabla", "bla") == "blabla");
};
