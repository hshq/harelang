use bufio;
use errors;
use encoding::utf8;
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
	defer io::close(file);

	let buf: [os::BUFSIZ]u8 = [0...];
	const file = bufio::buffered(file, buf, []);
	defer io::close(&file);

	for (true) {
		const line = match (bufio::scanline(&file)?) {
		case let bytes: []u8 =>
			yield match (strings::try_fromutf8(bytes)) {
			case utf8::invalid =>
				io::errorln("Warning: /etc/mime.types contains invalid UTF-8");
				return;
			case let s: str =>
				yield s;
			};
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
};

fn register_heap(mime: *mimetype...) void = {
	let i = len(heap_db);
	append(heap_db, mime...);
	for (i < len(heap_db); i += 1) {
		hashtable_insert(heap_db[i]);
	};
};
