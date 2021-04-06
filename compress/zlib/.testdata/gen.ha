use bufio;
use fmt;
use fs;
use io;
use os;

fn write(name: str, buf: []u8) void = {
	fmt::printfln("const {}: []u8 = [", name);
	for (let i = 0z; i < len(buf); i += 1) {
		fmt::print("\t");
		for (let j = 0z; j < 11 && i < len(buf) - 1; j += 1) {
			fmt::printf("0x{:02X}, ", buf[i]);
			i += 1;
		};
		fmt::printfln("0x{:02X},", buf[i]);
	};
	fmt::println("];\n");
};

export fn main() void = {
	const vectors: [_](str, str) = [
		("null_in", "null_out"),
		("hamlet_in", "hamlet_out"),
		("rand_in", "rand_out"),
	];

	for (let i = 0z; i < len(vectors); i += 1) {
		let in = match (os::open(vectors[i].0, fs::flags::RDONLY)) {
			s: *io::stream => s,
			e: fs::error => fmt::fatal(fs::strerror(e)),
		};
		defer io::close(in);
		let ins = bufio::dynamic(io::mode::WRITE);
		match (io::copy(ins, in)) {
			size => void,
			e: io::error => fmt::fatal(io::strerror(e)),
		};
		let inb = bufio::finish(ins);
		defer free(inb);
		write(vectors[i].0, inb);

		let out = match (os::open(vectors[i].1, fs::flags::RDONLY)) {
			s: *io::stream => s,
			e: fs::error => fmt::fatal(fs::strerror(e)),
		};
		defer io::close(out);
		let outs = bufio::dynamic(io::mode::WRITE);
		match (io::copy(outs, out)) {
			size => void,
			e: io::error => fmt::fatal(io::strerror(e)),
		};
		let outb = bufio::finish(ins);
		defer free(outb);
		write(vectors[i].1, outb);
	};

	fmt::printfln("const vectors: [_](*[]u8, *[]u8) = [");
	for (let i = 0z; i < len(vectors); i += 1) {
		fmt::printfln("\t(&{}, &{}),", vectors[i].0, vectors[i].1);
	};
	fmt::println("];");
};
