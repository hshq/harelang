// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use encoding::utf8;
use fmt;
use fs;
use io;
use os;
use strings;

@init fn init() void = {
	// Done in a separate function so we can discard errors here
	load_systemdb(): void;
};

fn load_systemdb() (void | fs::error | io::error | utf8::invalid) = {
	const file = os::open(SYSTEM_DB)?;
	defer io::close(file)!;

	let sc = bufio::newscanner(file);
	defer bufio::finish(&sc);

	for (let line => bufio::scan_line(&sc)?) {
		line = strings::trim(line);
		if (strings::hasprefix(line, "#") || len(line) == 0) {
			continue;
		};

		const items = strings::cut(line, "\t");
		const mime = strings::trim(items.0),
			exts = strings::trim(items.1);
		if (len(exts) == 0) {
			continue;
		};

		const tok = strings::tokenize(exts, " ");
		let entry = alloc(mimetype {
			mime = strings::dup(mime),
			exts = [],
		});
		for (let ext => strings::next_token(&tok)) {
			append(entry.exts, strings::dup(ext));
		};
		register_heap(entry);
	};
};

fn register_heap(mime: *mimetype) void = {
	let i = len(heap_db);
	append(heap_db, mime);
	for (i < len(heap_db); i += 1) {
		hashtable_insert(heap_db[i]);
	};
};
