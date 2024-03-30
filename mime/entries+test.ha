// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

const text_plain: mimetype = mimetype {
	mime = "text/plain",
	exts = ["txt"],
};

const text_hare: mimetype = mimetype {
	mime = "text/x-hare",
	exts = ["ha"],
};

@init fn init() void = {
	register(&text_plain, &text_hare);
};

@test fn lookup_mime() void = {
	assert(lookup_mime("foo/bar") == null);

	const result = lookup_mime("text/plain") as *mimetype;
	assert(result.mime == "text/plain");
	assert(len(result.exts) >= 1);

	let extfound = false;
	for (let ext .. result.exts) {
		if (ext == "txt") {
			extfound = true;
		};
	};
	assert(extfound);

	const result = lookup_mime("text/x-hare") as *mimetype;
	assert(result.mime == "text/x-hare");
	assert(len(result.exts) >= 1);

	let extfound = false;
	for (let ext .. result.exts) {
		if (ext == "ha") {
			extfound = true;
		};
	};
	assert(extfound);
};


@test fn lookup_ext() void = {
	assert(lookup_ext("foo") == null);
	assert(lookup_ext(".foo") == null);

	const result = lookup_ext("txt") as *mimetype;
	assert(result.mime == "text/plain");

	let extfound = false;
	for (let ext .. result.exts) {
		if (ext == "txt") {
			extfound = true;
		};
	};
	assert(extfound);

	const result = lookup_ext(".txt") as *mimetype;
	assert(result.mime == "text/plain");

	const result = lookup_ext("ha") as *mimetype;
	assert(result.mime == "text/x-hare");
	assert(len(result.exts) >= 1);

	let extfound = false;
	for (let ext .. result.exts) {
		if (ext == "ha") {
			extfound = true;
		};
	};
	assert(extfound);
};
