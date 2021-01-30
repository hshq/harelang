use io;
use os;

export fn main() void = {
	io::println("Hello, world!");
	for (let i = 0z; i < len(os::args); i += 1z) {
		io::println(os::args[i]);
	};
};
