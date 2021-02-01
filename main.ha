use encoding::utf8;
use strings;
use io;

export fn main() void = {
	const expected = ['こ', 'ん', 'に', 'ち', 'は'];
	let decoder = utf8::decode("こんにちは");
	let i = 0z;
	for (true) {
		match (utf8::next(&decoder)) {
			r: rune => {
				assert(r == expected[i]);
				i += 1z;
			},
			void => {
				assert(i == len(expected));
				break;
			},
			utf8::more    => abort("more"),
			utf8::invalid => abort("invalid"),
		};
	};
	io::println("tada!");
};
