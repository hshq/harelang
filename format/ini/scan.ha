// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use encoding::utf8;
use fmt;
use io;
use strings;

export type scanner = struct {
	scan: bufio::scanner,
	lineno: size,
	section: str,
};

// Creates an INI file scanner. Use [[next]] to read entries. The caller must
// call [[finish]] once they're done with this object.
export fn scan(in: io::handle) scanner = {
	return scanner {
		scan = bufio::newscanner(in),
		lineno = 1,
		...
	};
};

// Frees resources associated with a [[scanner]].
export fn finish(sc: *scanner) void = {
	bufio::finish(&sc.scan);
	free(sc.section);
};

// An entry in an INI file: (section, key, value).
export type entry = (const str, const str, const str);

// Duplicates an [[entry]]. Use [[entry_finish]] to get rid of it.
export fn entry_dup(ent: entry) entry = (
	strings::dup(ent.0),
	strings::dup(ent.1),
	strings::dup(ent.2),
);

// Frees an [[entry]] previously duplicated with [[entry_dup]].
export fn entry_finish(ent: entry) void = {
	free(ent.0);
	free(ent.1);
	free(ent.2);
};

// Returns the next entry from an INI file. The return value is borrowed from
// the [[scanner]]. Use [[entry_dup]] to retain a copy.
export fn next(sc: *scanner) (entry | io::EOF | error) = {
	for (const line => bufio::scan_line(&sc.scan)?) {
		defer sc.lineno += 1;

		const line = strings::trim(line);
		if (len(line) == 0 || strings::hasprefix(line, "#")) {
			continue;
		};

		if (strings::hasprefix(line, "[")) {
			const end = match (strings::index(line, ']')) {
			case let idx: size =>
				yield idx;
			case void =>
				return sc.lineno: syntaxerr;
			};
			free(sc.section);
			sc.section = strings::dup(strings::sub(line, 1, end));
			continue;
		};

		const eq = match (strings::index(line, '=')) {
		case let idx: size =>
			yield idx;
		case void =>
			return sc.lineno: syntaxerr;
		};
		return (
			sc.section,
			strings::sub(line, 0, eq),
			strings::sub(line, eq + 1, strings::end),
		);
	};

	return io::EOF;
};
