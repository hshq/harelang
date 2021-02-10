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

@init fn init_environ() void = {
	if (rt::argc < len(args_static)) {
		args = args_static[..rt::argc];
		for (let i = 0z; i < rt::argc; i += 1) {
			args[i] = strings::from_c(rt::argv[i]);
		};
	} else {
		args = alloc([]str, [], rt::argc);
		for (let i = 0z; i < rt::argc; i += 1) {
			append(args, strings::from_c(rt::argv[i]));
		};
	};

};

@fini fn fini_environ() void = {
	if (rt::argc >= len(args_static)) {
		free(args);
	};
};

// Looks up an environment variable and returns its value, or void if unset.
export fn getenv(name: const str) (str | void) = {
	const name_b = strings::to_utf8(name);
	for (let i = 0z; rt::envp[i] != null; i += 1) {
		const item = rt::envp[i]: *[*]u8;
		const eq: size = match (bytes::index(item[..], '=': u32: u8)) {
			void => abort("Environment violates System-V invariants"),
			i: size => i,
		};
		if (bytes::equal(name_b, item[..eq])) {
			const ln = strings::c_strlen(item: *const char);
			return strings::from_utf8(item[eq+1..ln]);
		};
	};
};
