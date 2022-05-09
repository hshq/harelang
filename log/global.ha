use io;
use os;

// The default global logger instance.
export let global: *logger = &_global;

let _global: stdlogger = stdlogger {
	println = &log_println,
	printfln = &log_printfln,
	sink = -1: io::file,
};

@init fn init() void = {
	// XXX: Would be nice not to have to do this
	_global.sink = os::stderr;
};

// Sets the global logger instance to the provided logger.
export fn setlogger(log: *logger) void = {
	global = log;
};
