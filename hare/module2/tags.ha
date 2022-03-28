use ascii;
use path;
use strings;
use strio;

// The inclusive/exclusive state for a build tag.
export type tag_mode = enum {
	INCLUSIVE,
	EXCLUSIVE,
};

// A build tag, e.g. +x86_64.
export type tag = struct {
	name: str,
	mode: tag_mode,
};

// Given a file or directory name, parses and returns any applicable tags.
export fn parsename(name: str) []tag = {
	let base = path::extension(name).0;
	let p = strings::index(base, '+');
	let m = strings::index(base, '-');
	if (p is void && m is void) {
		return [];
	};
	let i: size =
		if (p is void && m is size) m: size
		else if (m is void && p is size) p: size
		else if (m: size < p: size) m: size
		else p: size;
	let tags = strings::sub(base, i, strings::end);
	let tags = match (parsetags(tags)) {
	case void =>
		return [];
	case let t: []tag =>
		yield t;
	};
	let base = strings::sub(base, 0, i);
	return tags;
};

// Parses a set of build tags, returning void if the string is an invalid tag
// set. The caller must free the return value with [[tags_free]].
export fn parsetags(in: str) ([]tag | void) = {
	let tags: []tag = [];
	let iter = strings::iter(in);
	for (true) {
		let t = tag { ... };
		let m = match (strings::next(&iter)) {
		case void =>
			break;
		case let r: rune =>
			yield r;
		};
		t.mode = switch (m) {
		case =>
			tags_free(tags);
			return;
		case '+' =>
			yield tag_mode::INCLUSIVE;
		case '-' =>
			yield tag_mode::EXCLUSIVE;
		};
		let buf = strio::dynamic();
		for (true) match (strings::next(&iter)) {
		case void =>
			break;
		case let r: rune =>
			if (ascii::isalnum(r) || r == '_') {
				strio::appendrune(&buf, r)!;
			} else {
				strings::push(&iter, r);
				break;
			};
		};
		t.name = strio::string(&buf);
		append(tags, t);
	};
	return tags;
};

// Compares two tag sets and tells you if they are compatible.
export fn tagcompat(conf: []tag, target: []tag) bool = {
	// XXX: O(n²), lame
	for (let i = 0z; i < len(target); i += 1) {
		let present = false;
		for (let j = 0z; j < len(conf); j += 1) {
			if (conf[j].name == target[i].name) {
				present = conf[j].mode == tag_mode::INCLUSIVE;
				break;
			};
		};
		switch (target[i].mode) {
		case tag_mode::INCLUSIVE =>
			if (!present) return false;
		case tag_mode::EXCLUSIVE =>
			if (present) return false;
		};
	};
	return true;
};

// Frees a set of tags.
export fn tags_free(tags: []tag) void = {
	for (let i = 0z; i < len(tags); i += 1) {
		free(tags[i].name);
	};
	free(tags);
};
