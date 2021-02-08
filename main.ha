use fmt;
use os;
use os::exec;

export fn main() void = {
	let cmd = match (exec::cmd(os::args[1], os::args[2..]...)) {
		err: exec::error =>
			fmt::fatal("Error: exec::cmd: {}", exec::errstr(err)),
		cmd: exec::command => cmd,
	};
	match (exec::start(&cmd)) {
		err: exec::error =>
			fmt::fatal("Error: exec::start: {}", exec::errstr(err)),
		* => void,
	};
};
