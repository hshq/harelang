// Allocates a segment.
fn segmalloc(n: size) nullable *void = {
	return match (mmap(null, n, PROT_READ | PROT_WRITE,
		MAP_PRIVATE | MAP_ANON, -1, 0)) {
	case err: errno =>
		assert(err == ENOMEM: errno);
		yield null;
	case p: *void =>
		yield p;
	};
};

// Frees a segment allocated with segmalloc.
fn segfree(p: *void, s: size) void = {
	match (munmap(p, s)) {
		case err: errno =>
			abort("munmap failed");
		case void => void;
	};
};
