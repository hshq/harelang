use os;

@test fn _abort() void = {
	expectabort();
	abort("Intentional failure");
};

@test fn exit() void = {
	expectabort();
	os::exit(1);
};
