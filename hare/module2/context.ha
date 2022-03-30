use ascii;
use dirs;
use os;
use fs;
use sort;
use strings;

// Configuration options for a Hare module context.
export type config = struct {
	fs: *fs::fs,
	paths: []str,
	tags: []tag,
	defines: []str,
};

// A Hare module context.
export type context = struct {
	fs: *fs::fs,
	paths: []str,
	cache: str,
	tags: []tag,
	defines: []str,
};

// Creates a Hare module context using the specified configuration.
//
// The context borrows the config parameters for the duration of its lifetime.
// Call [[context_finish]] to clean up resources associated with this object.
export fn newcontext(conf: *config) context = {
	let paths: []str = match (os::getenv("HAREPATH")) {
	case void =>
		yield alloc(conf.paths...);
	case let path: str =>
		let paths: []str = [];

		const tok = strings::tokenize(path, ":");
		for (true) match (strings::next_token(&tok)) {
		case let tok: str =>
			append(paths, tok);
		case void =>
			break;
		};

		yield paths;
	};
	insert(paths[0], ".");

	const cache = match (os::getenv("HARECACHE")) {
	case void =>
		yield strings::dup(dirs::cache("hare"));
	case let s: str =>
		yield strings::dup(s);
	};

	let tags: []tag = alloc(conf.tags...);
	sort::sort(tags, size(tag), &tag_cmp);
	// XXX: We might want to check for conflicting tags (e.g. +linux-linux)

	return context {
		fs = conf.fs,
		tags = tags,
		defines = conf.defines,
		paths = paths,
		cache = cache,
	};
};

// Frees resources associated with a [[context]].
export fn context_finish(ctx: *context) void = {
	free(ctx.paths); // The strings themselves are borrowed
	free(ctx.cache);
	free(ctx.tags);
};

fn tag_cmp(a: const *void, b: const *void) int = {
	const a = a: const *tag;
	const b = b: const *tag;
	return ascii::strcmp(a.name, b.name) as int;
};
