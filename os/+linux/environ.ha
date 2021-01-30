use rt;
use strings;
use types;

// The command line arguments provided to the program. By convention, the first
// member is usually the name of the program.
export let args: []str = [];

@init fn init() void = {
	args = alloc([]str, [], rt::argc);
	(&args: *types::slice).length = rt::argc; // HORRIBLE HACK
	for (let i = 0z; i < rt::argc; i += 1z) {
		args[i] = strings::from_c(rt::argv[i]);
	};
};

@fini fn fini() void = {
	free(args);
};
