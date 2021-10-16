use bufio;
use fmt;
use fs;
use io;
use os;

fn write(name: str, buf: []u8) void = {
	fmt::printfln("const {}: []u8 = [", name)!;
	for (let i = 0z; i < len(buf); i += 1) {
		fmt::print("\t")!;
		for (let j = 0z; j < 11 && i < len(buf) - 1; j += 1) {
			fmt::printf("0x{:02X}, ", buf[i])!;
			i += 1;
		};
		fmt::printfln("0x{:02X},", buf[i])!;
	};
	fmt::println("];\n")!;
};

export fn main() void = {
	const vectors: [_](str, str) = [
		("null_in", "null_out"),
		("hamlet_in", "hamlet_out"),
		("rand_in", "rand_out"),
	];

	for (let i = 0z; i < len(vectors); i += 1) {
		const in = os::open(vectors[i].0)!;
		defer io::close(in);
		const ins = bufio::dynamic(io::mode::WRITE);
		io::copy(ins, in)!;
		const inb = bufio::finish(ins);
		defer free(inb);
		write(vectors[i].0, inb);

		const out = os::open(vectors[i].1)!;
		defer io::close(out);
		const outs = bufio::dynamic(io::mode::WRITE);
		io::copy(outs, out)!;
		const outb = bufio::finish(ins);
		defer free(outb);
		write(vectors[i].1, outb);
	};

	fmt::printfln("const vectors: [_](*[]u8, *[]u8) = [")!;
	for (let i = 0z; i < len(vectors); i += 1) {
		fmt::printfln("\t(&{}, &{}),", vectors[i].0, vectors[i].1)!;
	};
	fmt::println("];")!;
};
