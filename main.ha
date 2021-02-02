use fmt;
use os;

export fn main() void = {
	let x = 1337;
	fmt::fprintf(os::stdout, "x: {} {}\n", 1337, "hello");
};
