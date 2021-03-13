// TODO: This file doesn't need to exist once we have working forward
// declarations

export type platform_cmd = int;

// Stores information about a child process.
export type process = int;

// Stores information about an exited process.
export type status = struct {
	status: int,
	// Not all of these members are supported on all operating systems.
	// Only utime and stime are guaranteed to be available.
	rusage: struct {
		// TODO: utime, stime
		maxrss: u64,
		minflt: u64,
		majflt: u64,
		inblock: u64,
		oublock: u64,
		nvcsw: u64,
		nivcsw: u64,
	},
};
