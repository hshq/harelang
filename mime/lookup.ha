// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use hash::fnv;
use strings;

// Looks up a Media Type based on the mime type string, returning null if
// unknown.
export fn lookup_mime(mime: str) const nullable *mimetype = {
	const hash = fnv::string(mime);
	const bucket = &mimetable[hash % len(mimetable)];
	for (let i = 0z; i < len(bucket); i += 1) {
		const item = bucket[i];
		if (item.mime == mime) {
			return item;
		};
	};
	return null;
};

@test fn lookup_mime() void = {
	assert(lookup_mime("foo/bar") == null);

	const result = lookup_mime("text/plain") as *mimetype;
	assert(result.mime == "text/plain");
	assert(len(result.exts) == 1);
	assert(result.exts[0] == "txt");

	const result = lookup_mime("text/x-hare") as *mimetype;
	assert(result.mime == "text/x-hare");
	assert(len(result.exts) == 1);
	assert(result.exts[0] == "ha");
};

// Looks up a Media Type based on a file extension, with or without the leading
// '.' character, returning null if unknown.
export fn lookup_ext(ext: str) const nullable *mimetype = {
	ext = strings::ltrim(ext, '.');
	const hash = fnv::string(ext);
	const bucket = &exttable[hash % len(exttable)];
	for (let i = 0z; i < len(bucket); i += 1) {
		const item = bucket[i];
		for (let j = 0z; j < len(item.exts); j += 1) {
			if (item.exts[j] == ext) {
				return item;
			};
		};
	};
	return null;
};

@test fn lookup_ext() void = {
	assert(lookup_ext("foo") == null);
	assert(lookup_ext(".foo") == null);

	const result = lookup_ext("txt") as *mimetype;
	assert(result.mime == "text/plain");
	assert(len(result.exts) == 1);
	assert(result.exts[0] == "txt");

	const result = lookup_ext(".txt") as *mimetype;
	assert(result.mime == "text/plain");

	const result = lookup_ext("ha") as *mimetype;
	assert(result.mime == "text/x-hare");
	assert(len(result.exts) == 1);
	assert(result.exts[0] == "ha");
};
