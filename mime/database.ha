use hash::fnv;
use strings;

// A pair of a Media Type and a list of file extensions associated with it. The
// extension list does not include the leading '.' character.
export type mimetype = struct {
	mime: str,
	exts: []str,
};

// List of media types with a statically allocated fields (though the list
// itself is dynamically allocated).
let static_db: []mimetype = [];

// List of media types with a heap-allocated fields, used when loading mime
// types from the system database.
let heap_db: []mimetype = [];

def MIME_BUCKETS: size = 256;

// Hash tables for efficient database lookup by mimetype or extension
let mimetable: [MIME_BUCKETS][]*mimetype = [[]...];
let exttable: [MIME_BUCKETS][]*mimetype = [[]...];

// Registers a Media Type and its extensions in the internal MIME database. This
// function is designed to be used by @init functions for modules which
// implement new Media Types.
export fn register(mime: mimetype...) void = {
	let i = len(static_db);
	append(static_db, mime...);
	for (i < len(static_db); i += 1) {
		const item = &static_db[i];
		const hash = fnv::string(item.mime);
		let bucket = &mimetable[hash % len(mimetable)];
		append(bucket, item);

		for (let i = 0z; i < len(item.exts); i += 1) {
			const hash = fnv::string(item.exts[i]);
			let bucket = &exttable[hash % len(exttable)];
			append(bucket, item);
			assert(len(bucket) > 0);
		};
	};
};

const builtins: [_]mimetype = [
	mimetype {
		mime = "text/plain",
		exts = ["txt"],
	},
	mimetype {
		mime = "text/x-hare",
		exts = ["ha"],
	},
];

@init fn init() void = {
	register(builtins...);
};

@fini fn fini() void = {
	for (let i = 0z; i < len(heap_db); i += 1) {
		free(heap_db[i].mime);
		strings::freeall(heap_db[i].exts);
	};
	free(heap_db);
	free(static_db);
};
