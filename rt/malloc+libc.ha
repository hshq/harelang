// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Allocates n bytes of memory and returns a pointer to them, or null if there
// is insufficient memory.
export fn malloc(n: size) nullable *opaque = {
	return c_malloc(n);
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
	return c_realloc(p, n);
};

// Frees a pointer previously allocated with [[malloc]].
export @symbol("rt.free") fn free_(p: nullable *opaque) void = {
	c_free(p);
};

@symbol("malloc") fn c_malloc(size) nullable *opaque;
@symbol("realloc") fn c_realloc(nullable *opaque, size) nullable *opaque;
@symbol("free") fn c_free(nullable *opaque) void;
