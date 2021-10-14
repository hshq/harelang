type language = enum {
	C,
	HARE,
	PYTHON,
	MYRDDIN,
};

@test fn strenum() void = {
	const l = language::C;
	assert(strenum(type(language), &l) == "C");

	const l = language::HARE;
	assert(strenum(type(language), &l) == "HARE");

	const l = language::PYTHON;
	assert(strenum(type(language), &l) == "PYTHON");

	const l = language::MYRDDIN;
	assert(strenum(type(language), &l) == "MYRDDIN");
};

type perm = enum u8 {
	NONE    = 0,
	READ    = 1 << 0,
	WRITE   = 1 << 1,
	EXECUTE = 1 << 2,
};

@test fn strflag() void = {
	const perm = perm::READ;
	const res = strflag(type(perm), &perm);
	defer free(res);
	assert(res == "READ");

	const perm = perm::READ | perm::WRITE;
	const res = strflag(type(perm), &perm);
	defer free(res);
	assert(res == "READ|WRITE");

	const perm = perm::WRITE | perm::EXECUTE;
	const res = strflag(type(perm), &perm);
	defer free(res);
	assert(res == "WRITE|EXECUTE");

	const perm = perm::NONE;
	const res = strflag(type(perm), &perm);
	defer free(res);
	assert(res == "NONE");
};
