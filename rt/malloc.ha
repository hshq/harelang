// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// This is a simple memory allocator, based on
// Appel, Andrew W., and David A. Naumann. "Verified sequential malloc/free"
// but with logarithmic bin sizing and additional safety checks. Not thread-safe

// A group of blocks that were allocated together.
export type chunk = union {
	padding: size, // TODO: track number of active allocations here
	data: [*]u8,
};

// Metadata for a block.
export type meta = struct {
	union {
		sz: size,
		next: uintptr,
	},
	user: [*]u8,
};

// Size of the header/footer for allocations.
def META: size = size(size);

// Alignment for pointers returned by malloc.
// XXX: arch
def ALIGN: size = 16;

// Allocation granularity for large allocs. Only used to allow verifying large
// heap pointers, doesn't necessarily need to match system page size.
def PAGESZ: size = 4096;

// Amount of memory to allocate at a time for chunks (2MiB).
def CHUNKSZ: size = 1 << 21;

// Byte to fill allocations with while they're not in use.
def POISON: u8 = 0x69;

export type memory_heap = struct {
	// Number of allocations currently in flight.
	cur_allocs: size,
	// Freelists for blocks up to 2048 bytes.
	bins: [9]nullable *meta,
	// The chunk to allocate from if there are no blocks available in the
	// right freelist.
	cur_chunk: (*chunk, size),
};

let static_heap = memory_heap {
	cur_allocs = 0,
	bins = [null...],
	cur_chunk = (null: *chunk, CHUNKSZ),
};

let heap = &static_heap;

export fn newheap() memory_heap = {
	// Re-initializes the heap from scratch, abandoning all prior memory
	// allocations and returning the previous heap.
	//
	// This function is designed to be called by debug:: in a scenario where
	// the heap has been corrupted. It abandons the corrupt heap and
	// prepares a fresh heap which debug:: can use to allocate memory for
	// any operations it needs to perform during clean-up.
	const old = *heap;
	*heap = memory_heap {
		cur_allocs = 0,
		bins = [null...],
		cur_chunk = (null: *chunk, CHUNKSZ),
	};
	return old;
};

// Allocates n bytes of memory and returns a pointer to them, or null if there
// is insufficient memory.
export fn malloc(n: size) nullable *opaque = {
	if (n == 0) return null;
	if (size_islarge(n)) {
		// Round up to PAGESZ and just use mmap directly
		n = realsz(n);
		let m = match (segmalloc(n + ALIGN + META)) {
		case null =>
			return null;
		case let p: *opaque =>
			yield (p: uintptr + ALIGN - META): *meta;
		};

		m.sz = n;
		*(&m.user[n]: *size) = n; // For out-of-bounds write detection
		heap.cur_allocs += 1;
		return &m.user;
	};

	let bin = size_getbin(n), sz = bin_getsize(bin);
	let m = match (heap.bins[bin]) {
	case null =>
		if (heap.cur_chunk.1 + META + sz + META > CHUNKSZ) {
			// No space left in this chunk, allocate a new one
			match (segmalloc(CHUNKSZ)) {
			case null =>
				return null;
			case let p: *opaque =>
				heap.cur_chunk = (p: *chunk, size(size));
			};
		};

		// Allocate a new block from the currently-active chunk
		let m = &heap.cur_chunk.0.data[heap.cur_chunk.1]: *meta;
		heap.cur_chunk.1 += META + sz;
		m.sz = sz;
		*(&m.user[sz]: *size) = sz;
		yield m;
	case let m: *meta =>
		// Pop a block off the freelist
		heap.bins[bin] = meta_next(m);
		checkpoison(m, sz);
		m.sz = sz;
		yield m;
	};

	heap.cur_allocs += 1;
	return &m.user;
};

// Frees an allocation returned by [[malloc]]. Freeing any other pointer, or
// freeing a pointer that's already been freed, will cause an abort.
export @symbol("rt.free") fn free_(p: nullable *opaque) void = {
	let m = match (p) {
	case null =>
		return;
	case let p: *opaque =>
		yield getmeta(p);
	};
	heap.cur_allocs -= 1;

	if (size_islarge(m.sz)) {
		// Pass through to munmap
		segfree((p: uintptr - ALIGN): *opaque, m.sz + ALIGN + META);
		return;
	};

	// Push onto freelist
	let bin = size_getbin(m.sz);
	m.user[..m.sz] = [POISON...];
	m.next = heap.bins[bin]: uintptr | 0b1;
	heap.bins[bin] = m;
};

// Changes the allocation size of a pointer to n bytes. If n is smaller than
// the prior allocation, it is truncated; otherwise the allocation is expanded
// and the values of the new bytes are undefined. May return a different pointer
// than the one given if there is insufficient space to expand the pointer
// in-place. Returns null if there is insufficient memory to support the
// request.
export fn realloc(p: nullable *opaque, n: size) nullable *opaque = {
	if (n == 0) {
		free(p);
		return null;
	};
	let m = match (p) {
	case null =>
		return malloc(n);
	case let p: *opaque =>
		yield getmeta(p);
	};
	if (realsz(n) == m.sz) return p;

	let new = match (malloc(n)) {
	case null =>
		return null;
	case let new: *opaque =>
		yield new;
	};
	memcpy(new, &m.user, if (n < m.sz) n else m.sz);
	free(p);
	return new;
};

// Gets the metadata for a given allocation. The provided pointer must have been
// returned by [[malloc]] or [[realloc]] and must not have been freed.
export fn getmeta(p: *opaque) *meta = {
	let m = (p: uintptr - META): *meta;
	validatemeta(m, false);
	assert(m.sz & 0b1 == 0,
		"tried to get metadata for already-freed pointer (double free?)");
	return m;
};


// Find the maximum allocation size for a given bin.
fn bin_getsize(bin: size) size = {
	// Would need to have bin 0 be ALIGN rather than 0 in this case
	static assert(ALIGN != META);

	// Space bins logarithmically
	let sz = if (bin == 0) 0z else 1 << (bin - 1);

	// And make sure that (bin_getsize(n) + META) % ALIGN == 0, while erring on
	// the side of bin sizes slightly larger than powers of two
	return sz * ALIGN + ALIGN - META;
};

// Find the bin for a given allocation size.
fn size_getbin(sz: size) size = {
	// Undo alignment fudging. Equivalent to
	// ceil((sz - ALIGN + META) / ALIGN)
	sz = (sz + META - 1) / ALIGN;

	// Then undo exponentiation
	if (sz == 0) return 0;
	let ret = 0z;
	for (1 << ret < sz; ret += 1) void;
	return ret + 1;
};

// Returns true if a given allocation size should use mmap directly.
fn size_islarge(sz: size) bool = sz > bin_getsize(len(heap.bins) - 1);

// Gets the next block on the freelist.
fn meta_next(m: *meta) nullable *meta = {
	assert(m.next & 0b1 == 0b1,
		"expected metadata on freelist to be marked as free (heap corruption?)");
	return (m.next & ~0b1): nullable *meta;
};

// Round a user-requested allocation size up to the next-smallest size we can
// allocate.
fn realsz(sz: size) size = {
	if (size_islarge(sz)) {
		sz += ALIGN + META;
		if (sz % PAGESZ != 0) sz += PAGESZ - sz % PAGESZ;
		return sz - ALIGN - META;
	};

	return bin_getsize(size_getbin(sz));
};


// Check for memory errors related to a given block of memory.
fn validatemeta(m: *meta, shallow: bool) void = {
	assert(&m.user: uintptr % ALIGN == 0,
		"invalid alignment for metadata pointer (heap corruption?)");
	// If we were recursively called to check a next pointer, the block
	// needs to be marked as free, abort in meta_next() if it's not
	if (m.sz & 0b1 == 0b1 || shallow == true) {
		// Block is currently free, verify that it points to a valid
		// next block
		match (meta_next(m)) {
		case null => void;
		case let next: *meta =>
			assert(next: uintptr % ALIGN == META,
				"invalid metadata for small allocation on freelist (heap corruption?)");
			if (!shallow) validatemeta(next, true);
		};
		return;
	};

	// Block is currently allocated, verify that its size is valid
	let second = &m.user[m.sz]: *meta;
	if (size_islarge(m.sz)) {
		assert((&m.user: uintptr - ALIGN) % PAGESZ == 0,
			"invalid large allocation address (non-heap pointer?)");
		assert((m.sz + ALIGN + META) % PAGESZ == 0,
			"invalid metadata for large allocation (non-heap pointer?)");
		assert(second.sz == m.sz,
			"invalid secondary metadata for large allocation (out-of-bounds write?)");
		return;
	};

	assert(bin_getsize(size_getbin(m.sz)) == m.sz,
		"invalid metadata for small allocation (non-heap pointer?)");
	if (second.sz & 0b1 == 0b1) {
		// Next block after it in the chunk is free, recursively verify
		// that it's valid
		validatemeta(second, false);
		return;
	};

	// Note that we can't recurse here because the "next block" might
	// actually be the extra metadata at the end of the chunk (which is
	// never marked as being on the freelist
	assert(!size_islarge(second.sz),
		"invalid secondary metadata for small allocation (out-of-bounds write?)");
	assert(bin_getsize(size_getbin(second.sz)) == second.sz,
		"invalid secondary metadata for small allocation (out-of-bounds write?)");
};

// Verify that a pointer on a free list hasn't been touched since it was added.
fn checkpoison(m: *meta, sz: size) void = {
	match (meta_next(m)) {
	case null => void;
	case let next: *meta =>
		validatemeta(next, false);
	};
	for (let i = 0z; i < sz; i += 1) {
		assert(m.user[i] == POISON, "invalid poison data on freelist (use after free?)");
	};
};

@fini fn checkleaks() void = {
	for (let i = 0z; i < len(heap.bins); i += 1) {
		for (let m = heap.bins[i]; m != null; m = meta_next(m as *meta)) {
			checkpoison(m as *meta, bin_getsize(i));
		};
	};
	// TODO: Need a debugging malloc that tracks backtraces for
	// currently-active allocations in order to help with finding leaks
	// before we enable this by default. Also need to make sure that this is
	// run after the rest of @fini in order to guarantee that we see all
	// frees
	//assert(heap.cur_allocs == 0, "memory leak");
};
