// Allocates a segment.
fn segmalloc(n: size) nullable *void = {
	let p: *void = mmap(null, n,
		PROT_READ | PROT_WRITE,
		MAP_PRIVATE | MAP_ANON, -1, 0z);
	// TODO: remove the cast to nullable *void
	return if (p: uintptr: int == -ENOMEM) null: nullable *void else p: nullable *void;
};

// Frees a segment allocated with segmalloc.
fn segfree(p: *void, s: size) int = munmap(p, s);

// Marks a segment as writable and drops the execute bit.
fn segwrite(seg: *void, n: size) void = mprotect(seg, n, PROT_READ | PROT_WRITE);

// Marks a segment as executable and drops the write bit.
fn segexec(seg: *void, n: size) void = mprotect(seg, n, PROT_READ | PROT_EXEC);
