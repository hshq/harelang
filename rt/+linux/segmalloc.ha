// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>

// Allocates a segment.
fn segmalloc(n: size) nullable *opaque = {
	return match (mmap(null, n, PROT_READ | PROT_WRITE,
		MAP_PRIVATE | MAP_ANON, -1, 0)) {
	case let err: errno =>
		assert(err == ENOMEM: errno);
		yield null;
	case let p: *opaque =>
		yield p;
	};
};

// Frees a segment allocated with segmalloc.
fn segfree(p: *opaque, s: size) void = {
	match (munmap(p, s)) {
		case let err: errno =>
			abort("munmap failed");
		case void => void;
	};
};
