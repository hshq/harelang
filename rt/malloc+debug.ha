// This is a very simple "debug" allocator which works by allocating only via
// mmap and returning pointers to the end of the segment such that any writes
// beyond the end will cause an immediate segfault to occur.
//
// Ultimately, this should be replaced with a much more sophisticated debugging
// allocator.
let pagesz: size = 4096;

def AUXV_PAGESZ: u64 = 6;

type auxv64 = struct {
	a_type: u64,
	union {
		a_val: u64,
		a_ptr: *void,
		a_fnc: *fn() void,
	}
};

@init fn init() void = {
	let i = 0;
	for (rt::envp[i] != null) {
		i += 1;
	};
	let auxv = &rt::envp[i + 1]: *[*]auxv64;
	for (let i = 0z; auxv[i].a_type != 0; i += 1) {
		if (auxv[i].a_type == AUXV_PAGESZ) {
			pagesz = auxv[i].a_val: size;
			break;
		};
	};
};

export fn malloc(n: size) nullable *void = {
	if (n == 0) {
		return null;
	};
	let z = n + size(*void) + size(size);
	if (z % pagesz != 0) {
		z += pagesz - z % pagesz;
	};
	let seg = match (segmalloc(z)) {
		null => return null,
		ptr: *void => ptr,
	};
	let user = &(seg: *[*]u8)[z - n];
	let segptr = &(user: *[*]*void)[-1];
	let szptr = &(segptr: *[*]size)[-1];
	*segptr = seg;
	*szptr = n;
	return user;
};

export @symbol("rt.free") fn free_(_p: nullable *void) void = {
	if (_p != null) {
		let user = _p: *void;
		let segptr = &(user: *[*]*void)[-1];
		let szptr = &(segptr: *[*]size)[-1];
		let z = *szptr + size(*void) + size(size);
		if (z % pagesz != 0) {
			z += pagesz - z % pagesz;
		};
		segfree(*segptr, z);
	};
};

export fn realloc(user: nullable *void, n: size) nullable *void = {
	if (n == 0) {
		free(user);
		return null;
	} else if (user == null) {
		return malloc(n);
	};

	let user = user: *void;
	let segptr = &(user: *[*]*void)[-1];
	let szptr = &(segptr: *[*]size)[-1];
	let z = *szptr;

	let new = malloc(n);
	if (new != null) {
		memcpy(new: *void, user, if (z < n) z else n);
		free(user);
	};

	return new;
};
