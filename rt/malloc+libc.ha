// License: MPL-2.0
// (c) 2021 Alexey Yerin <yyp@disroot.org>

// Allocates n bytes of memory and returns a pointer to them, or null if there
// is insufficient memory.
export fn malloc(n: size) nullable *void = {
	return c_malloc(n);
};

// Changes the allocation size of a pointer to n bytes. If n is smaller than
// the prior allocation, it is truncated; otherwise the allocation is expanded
// and the values of the new bytes are undefined. May return a different pointer
// than the one given if there is insufficient space to expand the pointer
// in-place. Returns null if there is insufficient memory to support the
// request.
export fn realloc(p: nullable *void, n: size) nullable *void = {
	return c_realloc(p, n);
};

// Frees a pointer previously allocated with [[malloc]].
export @symbol("rt.free") fn free_(p: nullable *void) void = {
	c_free(p);
};

@symbol("malloc") fn c_malloc(size) nullable *void;
@symbol("realloc") fn c_realloc(nullable *void, size) nullable *void;
@symbol("free") fn c_free(nullable *void) void;
