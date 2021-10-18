type language = enum {
	C,
	HARE,
	PYTHON,
	MYRDDIN,
};

@test fn strenum() void = {
	assert(strenum(type(language), &language::C) == "C");
	assert(strenum(type(language), &language::HARE) == "HARE");
	assert(strenum(type(language), &language::PYTHON) == "PYTHON");
	assert(strenum(type(language), &language::MYRDDIN) == "MYRDDIN");
};

type perm = enum u8 {
	NONE    = 0,
	READ    = 1 << 0,
	WRITE   = 1 << 1,
	EXECUTE = 1 << 2,
};

@test fn strflag() void = {
	const res = strflag(type(perm), &perm::READ);
	defer free(res);
	assert(res == "READ");

	const res = strflag(type(perm), &(perm::READ | perm::WRITE));
	defer free(res);
	assert(res == "READ|WRITE");

	const res = strflag(type(perm), &(perm::WRITE | perm::EXECUTE));
	defer free(res);
	assert(res == "WRITE|EXECUTE");

	const res = strflag(type(perm), &perm::NONE);
	defer free(res);
	assert(res == "NONE");
};
