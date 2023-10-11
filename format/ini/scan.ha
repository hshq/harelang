// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use encoding::utf8;
use fmt;
use io;
use strings;

export type scanner = struct {
	in: io::handle,
	line: str,
	lineno: size,
	section: str,
};

// Creates an INI file scanner. Use [[next]] to read entries. The caller must
// call [[finish]] once they're done with this object.
export fn scan(in: io::handle) scanner = scanner {
	in = in,
	lineno = 1,
	...
};

// Frees resources associated with a [[scanner]].
export fn finish(sc: *scanner) void = {
	free(sc.line);
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

// Returns the next entry from an INI file. The return value is overwritten on
// subsequent calls, use [[entry_dup]] or [[strings::dup]] to extend the
// lifetime of the entry or its fields respectively.
export fn next(sc: *scanner) (entry | io::EOF | error) = {
	for (true) {
		const line = match (bufio::read_line(sc.in)?) {
		case let b: []u8 =>
			yield strings::fromutf8(b)?;
		case io::EOF =>
			return io::EOF;
		};
		defer sc.lineno += 1;

		free(sc.line);
		sc.line = line;

		const line = strings::trim(sc.line);

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
};
