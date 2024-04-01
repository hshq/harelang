// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bytes;
use fs;
use hare::ast;
use os;
use path;
use sort;
use sort::cmp;
use strings;
use time;

// A file tag, e.g. +x86_64, or -libc.
export type tag = struct {
	// The name of the tag.
	name: str,
	// Whether the tag is inclusive (+tag) or not (-tag).
	include: bool,
};

// A set of sources for a module, filtered by a set of tags.
export type srcset = struct {
	// The last time the list of source files changed. Note that this is not
	// the last time that the source files themselves changed.
	mtime: time::instant,
	// Source directories traversed while finding these source files.
	dirs: []str,
	// The list of tags that were actually encountered while finding these
	// source files. These are sorted alphabetically, and are the set of
	// tags that should be used to find this module in the cache.
	seentags: []str,
	// hare source files (.ha)
	ha: []str,
	// assembly source files (.s)
	s: []str,
	// object source files (.o)
	o: []str,
	// linker scripts (.sc)
	sc: []str,
};

// Frees the resources associated with a [[srcset]].
export fn finish_srcset(srcs: *srcset) void = {
	strings::freeall(srcs.dirs);
	strings::freeall(srcs.seentags);
	strings::freeall(srcs.ha);
	strings::freeall(srcs.s);
	strings::freeall(srcs.o);
	strings::freeall(srcs.sc);
};

// Find the on-disk path and set of source files for a given module. The path is
// statically allocated and may be overwritten on subsequent calls.
export fn find(ctx: *context, loc: location) ((str, srcset) | error) = {
	match (loc) {
	case let buf: *path::buffer =>
		match (path_find(ctx, buf)) {
		case let s: srcset =>
			return (path::string(buf), s);
		case not_found =>
			return attach(locstr(loc), not_found);
		case let e: error =>
			return e;
		};
	case let ident: ast::ident =>
		let tok = strings::tokenize(ctx.harepath, ":");
		let next: (str | done) = ".";
		for (next is str; next = strings::next_token(&tok)) {
			if (!os::exists(next as str)) {
				continue;
			};

			static let buf = path::buffer { ... };
			path::set(&buf, os::realpath(next as str)?)?;
			for (let part .. ident) {
				path::push(&buf, part)?;
			};

			match (path_find(ctx, &buf)) {
			case let s: srcset =>
				return (path::string(&buf), s);
			case not_found => void;
			case let e: error =>
				return attach(strings::dup(path::string(&buf)), e);
			};
		};
		return attach(locstr(ident), not_found);
	};
};

fn path_find(ctx: *context, buf: *path::buffer) (srcset | error) = {
	// list of sources to return, with 3 extra fields prepended to allow
	// quick lookup and comparison. each item is e.g.:
	// ("basename", "ha", 2 (# of tags), ["path/-tag1/basename+tag2.ha"])
	// if len(srcs.3) != 1 at the end of _findsrcs() then there's a conflict
	let srcs: [](str, str, size, []str) = [];
	defer {
		for (let i = 0z; i < len(srcs); i += 1) {
			free(srcs[i].0);
			free(srcs[i].1);
			free(srcs[i].3);
		};
		free(srcs);
	};
	let mtime = time::INSTANT_MIN;
	let res = srcset { mtime = time::INSTANT_MIN, ... };

	_findsrcs(buf, ctx.tags, &srcs, &res, 0)?;
	for (let i = 0z; i < len(srcs); i += 1) {
		if (len(srcs[i].3) != 1) {
			return alloc(srcs[i].3...): file_conflict;
		};
		let out = switch (srcs[i].1) {
		case "ha" =>
			yield &res.ha;
		case "s" =>
			yield &res.s;
		case "o" =>
			yield &res.o;
		case "sc" =>
			yield &res.sc;
		case => abort();
		};
		append(out, srcs[i].3[0]);
	};

	// module needs either a hare source file or a README in order to be
	// valid. used to allow eg. shadowing foo::bar:: without accidentally
	// shadowing foo::
	if (len(res.ha) == 0) {
		path::push(buf, "README")?;
		defer path::pop(buf);
		if (!os::exists(path::string(buf))) {
			finish_srcset(&res);
			return not_found;
		};
	};

	sort::sort(res.dirs, size(str), &cmp::strs);
	sort::sort(res.ha, size(str), &cmp::strs);
	sort::sort(res.s, size(str), &cmp::strs);
	sort::sort(res.o, size(str), &cmp::strs);
	sort::sort(res.sc, size(str), &cmp::strs);
	return res;
};

// simple implementation but the reasons for it are delicate
//
// finding the right sources is conceptually simple: just collect all the
// files compatible with the tagset and then pick the best ones for each
// conflicting filename
//
// the mtime is the first weird part: you want to find the last time a file
// was added, moved, or deleted, but only for parts of the module relevant to
// the input tags. the edge-case here is "what if i renamed a subdirectory so
// that it's tags don't match". the solution is that you can just find the
// latest mtime of directories that get traversed, i.e. have matching tags.
// this is because the tag-compatible subset of the filetree constitutes
// a filetree in its own right, where a file being renamed to no longer be
// part of the tag-filetree is equivalent to it being deleted from the
// tag-filetree. the mtime-checking does not distinguish between renames
// and deletions, so we get this for free by checking mtimes in the underlying
// filesystem
//
// the second weird part is the seentags: the goal here is finding the subset
// of the input tags which were actually used while finding the srcset,
// so that the cache can be reused for two sets of input tags which don't
// produce different srcsets. the method used here is just to take note of
// the tags which were encountered while traversing the tree, and not to
// continue down a file path beyond the first incompatible tag. exploring
// this method, you could look at e.g "mod/+linux/+x86_64.ha". you might think
// that this should, in theory, produce 4 different cache versions, since
// there are 2 tags, each of which has 2 states; and using the method here
// would produce only 3: none, +linux, and +linux+x86_64. however, there are
// actually only 2 options: none, and +linux+x86_64, and the method here adds
// one redundant slot for +linux. this is because either tag on their own
// doesn't change whether the path matches, only both together. in practice,
// the redundancy in the method used here will cause minimal overhead, because
// it's likely that you do actually have a file with just one of the tags
// somewhere else in your module, or else you would have combined them into
// one tag. in any case, the method used here is fast because it gets to stop
// searching as soon as it can
fn _findsrcs(
	buf: *path::buffer,
	in_tags: []str,
	srcs: *[](str, str, size, []str),
	res: *srcset,
	tagdepth: size,
) (void | error) = {
	const pathstr = path::string(buf);
	const stat = match (os::stat(pathstr)) {
	case let stat: fs::filestat =>
		yield stat;
	case fs::error =>
		return;
	};

	let tmp = pathstr;
	for (fs::islink(stat.mode)) {
		if (time::compare(res.mtime, stat.mtime) < 0) {
			res.mtime = stat.mtime;
		};
		tmp = os::realpath(tmp)?;
		stat = os::stat(tmp)?;
	};

	if (fs::isfile(stat.mode)) {
		let ext = match (path::pop_ext(buf)) {
		case void =>
			return;
		case let ext: str =>
			yield ext;
		};
		switch (ext) {
		case "ha", "s", "o", "sc" => void;
		case =>
			return;
		};
		let filebytes = strings::toutf8(path::peek(buf) as str);
		path::push_ext(buf, ext)?;

		let split = tagindex(filebytes);
		let (base, tags) = (
			strings::fromutf8_unsafe(filebytes[..split]),
			strings::fromutf8_unsafe(filebytes[split..]),
		);

		let wanttags = match (parse_tags(tags)) {
		case let tags: []tag =>
			yield tags;
		case let e: error =>
			return attach(strings::dup(path::string(buf)), e);
		};
		defer free(wanttags);
		if (!seentags_compat(in_tags, wanttags, &res.seentags)) {
			return;
		};

		let ntags = tagdepth + len(wanttags);
		let bufstr = path::string(buf);
		for (let i = 0z; i < len(srcs); i += 1) {
			if (srcs[i].0 == base && srcs[i].1 == ext) {
				if (srcs[i].2 > ntags) {
					return;
				};
				if (srcs[i].2 < ntags) {
					srcs[i].2 = ntags;
					strings::freeall(srcs[i].3);
					srcs[i].3 = [];
				};
				append(srcs[i].3, strings::dup(bufstr));
				return;
			};
		};

		append(srcs, (
			strings::dup(base),
			strings::dup(ext),
			ntags,
			alloc([strings::dup(bufstr)]),
		));
		return;
	};

	if (!fs::isdir(stat.mode)) return; // ignore special files

	append(res.dirs, strings::dup(pathstr));
	if (time::compare(res.mtime, stat.mtime) < 0) {
		res.mtime = stat.mtime;
	};

	let iter = match (os::iter(pathstr)) {
	case let i: *fs::iterator =>
		yield i;
	case let e: fs::error =>
		return attach(strings::dup(pathstr), e);
	};
	defer fs::finish(iter);

	for (let d => fs::next(iter)?) {
		path::push(buf, d.name)?;
		defer path::pop(buf);

		if (fs::isdir(d.ftype)) {
			if (tagindex(strings::toutf8(d.name)) != 0) {
				continue;
			};
			let wanttags = match (parse_tags(d.name)) {
			case let tags: []tag =>
				yield tags;
			case let e: error =>
				return attach(strings::dup(path::string(buf)), e);
			};
			defer free(wanttags);
			if (!seentags_compat(in_tags, wanttags, &res.seentags)) {
				continue;
			};

			_findsrcs(buf, in_tags, srcs, res,
				tagdepth+len(wanttags))?;
		} else if (fs::isfile(d.ftype)) {
			_findsrcs(buf, in_tags, srcs, res, tagdepth)?;
		};
	};
};

fn tagindex(bs: []u8) size = {
	let i = 0z;
	for (i < len(bs) && bs[i] != '+' && bs[i] != '-'; i += 1) void;
	return i;
};

// Parses tags from a string. The tag themselves are borrowed from the input,
// but the caller must free the slice returned.
export fn parse_tags(s: str) ([]tag | error) = {
	let bs = strings::toutf8(s);
	if (bytes::contains(bs, '.')) {
		return tag_has_dot;
	};
	let tags: []tag = [];
	let start = tagindex(bs);
	if (start != 0) {
		return tag_bad_format;
	};
	for (start < len(bs)) {
		const end = start + 1 + tagindex(bs[start+1..]);
		append(tags, tag {
			name = strings::fromutf8_unsafe(bs[start+1..end]),
			include = bs[start] == '+',
		});
		start = end;
	};
	return tags;
};

// Checks if a set of tags are compatible with a tag requirement.
export fn tags_compat(have: []str, want: []tag) bool = {
	for (let t .. want) {
		let found = false;

		for (let ht .. have) {
			if (ht == t.name) {
				found = true;
				break;
			};
		};

		if (t.include ^^ found) {
			return false;
		};
	};
	return true;
};

// same as tags_compat, but also adds any relevant tags to a seentags list
// for use in _findsrcs.
fn seentags_compat(have: []str, want: []tag, seen: *[]str) bool = {
	for (let t .. want) {
		let found = false;

		for (let ht .. have) {
			if (ht == t.name) {
				insert_uniq(seen, t.name);
				found = true;
				break;
			};
		};

		if (t.include ^^ found) {
			return false;
		};
	};
	return true;
};
