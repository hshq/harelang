// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use hash::fnv;
use strings;

// Looks up a Media Type based on the mime type string, returning null if
// unknown.
export fn lookup_mime(mime: str) const nullable *mimetype = {
	const hash = fnv::string(mime);
	const bucket = &mimetable[hash % len(mimetable)];
	for (let item .. *bucket) {
		if (item.mime == mime) {
			return item;
		};
	};
	return null;
};

// Looks up a Media Type based on a file extension, with or without the leading
// '.' character, returning null if unknown.
export fn lookup_ext(ext: str) const nullable *mimetype = {
	ext = strings::ltrim(ext, '.');
	const hash = fnv::string(ext);
	const bucket = &exttable[hash % len(exttable)];
	for (let item .. *bucket) {
		for (let j = 0z; j < len(item.exts); j += 1) {
			if (item.exts[j] == ext) {
				return item;
			};
		};
	};
	return null;
};
