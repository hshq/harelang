use bytes;
use rt;
use strings;
use types;

// The command line arguments provided to the program. By convention, the first
// member is usually the name of the program.
export let args: []str = [];

// Statically allocate arg strings if there are few enough arguments, saves a
// syscall if we don't need it.
let args_static: [32]str = [""...];

@init fn init() void = {
	if (rt::argc < len(args_static)) {
		args = args_static[..rt::argc];
	} else {
		args = alloc([]str, [], rt::argc);
		(&args: *types::slice).length = rt::argc; // HORRIBLE HACK
	};

	for (let i = 0z; i < rt::argc; i += 1z) {
		args[i] = strings::from_c(rt::argv[i]);
	};
};

@fini fn fini() void = {
	if (rt::argc >= len(args_static)) {
		free(args);
	};
};

// Looks up an environment variable and returns its value, or void if unset.
export fn getenv(name: str) (str | void) = {
	// TODO: Type promotion can simplify this null comparison
	for (let i = 0z; rt::envp[i] != null: nullable *char; i += 1z) {
		const item = rt::envp[i]: *[*]u8;
		const eq: size = match (bytes::index(item[..], '=': u32: u8)) {
			void => abort("Environment violates System-V invariants"),
			i: size => i,
		};
		if (bytes::equal(strings::to_utf8(name), item[..eq])) {
			const ln = strings::c_strlen(item: *const char);
			return strings::from_utf8(item[eq+1z..ln]);
		};
	};
	return void;
};
