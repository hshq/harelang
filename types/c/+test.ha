@test fn sizes() void = {
	static assert(size(short) == size(ushort));
	static assert(size(long) == size(ulong));
	static assert(size(longlong) == size(ulonglong));
	static assert(size(intmax) == size(uintmax));
	static assert(size(intptr) == size(uintptr));
	static assert(size(ssize) == size(size));
	static assert(size(short) <= size(int));
	static assert(size(long) >= 4);
	static assert(size(longlong) >= 8);

	static assert(align(short) == align(ushort));
	static assert(align(long) == align(ulong));
	static assert(align(longlong) == align(ulonglong));
	static assert(align(intmax) == align(uintmax));
	static assert(align(intptr) == align(uintptr));
	static assert(align(ssize) == align(size));
};

@test fn strings() void = {
	let s = fromstr("hello!");
	defer free(s);
	assert(tostr(s)! == "hello!");
	let s = nulstr("hello!\0");
	assert(tostr(s)! == "hello!");
};
