// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use encoding::utf8;
use fmt;
use fs;
use io;
use os;
use strings;

// Path to the system MIME database.
export def SYSTEM_DB: str = "/etc/mime.types";

@init fn init() void = {
	// Done in a separate function so we can discard errors here
	load_systemdb(): void;
};

fn load_systemdb() (void | fs::error | io::error) = {
	const file = os::open(SYSTEM_DB)?;

	let buf: [os::BUFSZ]u8 = [0...];
	const strm = bufio::init(file, buf, []);

	for (true) {
		const line = match (bufio::read_line(&strm)) {
		case let bytes: []u8 =>
			yield match (strings::fromutf8(bytes)) {
			case utf8::invalid =>
				fmt::errorln("Warning: /etc/mime.types contains invalid UTF-8")!;
				io::close(&strm)?;
				io::close(file)?;
				return;
			case let s: str =>
				yield s;
			};
		case let err: io::error =>
			io::close(&strm): void;
			io::close(file): void;
			return err;
		case io::EOF =>
			break;
		};
		defer free(line);

		const line = strings::trim(line);
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
		for (true) {
			const ext = match (strings::next_token(&tok)) {
			case let tok: str =>
				yield strings::trim(tok);
			case void =>
				break;
			};
			append(entry.exts, strings::dup(ext));
		};
		register_heap(entry);
	};

	io::close(&strm)?;
	io::close(file)?;
};

fn register_heap(mime: *mimetype...) void = {
	let i = len(heap_db);
	append(heap_db, mime...);
	for (i < len(heap_db); i += 1) {
		hashtable_insert(heap_db[i]);
	};
};
