use strings;
use io;

export fn main() void = {
	const expected = ['こ', 'ん', 'に', 'ち', 'は'];
	let iter = strings::iter("こんにちは");
	let i = 0z;
	for (true) {
		match (strings::next(&iter)) {
			r: rune => {
				assert(r == expected[i]);
				i += 1z;
			},
			void => {
				assert(i == len(expected));
				break;
			},
		};
	};
	io::println("tada!");
};
