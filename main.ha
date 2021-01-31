use io;
use os;

export fn main() void = {
	if (len(os::args) < 2z) {
		return;
	};

	match (os::getenv(os::args[1])) {
		void => io::println("variable unset"),
		var: str => io::println(var),
	};
};
