// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use math;
use strconv;

@test fn print() void = {
	let buf: [1024]u8 = [0...];

	assert(bsprint(buf, "hello world") == "hello world");
	assert(bsprintf(buf, "hello world") == "hello world");
	assert(bsprintf(buf, "{} {}", "hello", "world") == "hello world");
	assert(bsprintf(buf, "{0} {1}", "hello", "world") == "hello world");
	assert(bsprintf(buf, "{0} {0}", "hello", "world") == "hello hello");
	assert(bsprintf(buf, "{1} {0} {1}", "hello", "world") == "world hello world");

	const mod = &mods { width = 7, pad = ' ', ... };
	assert(bsprintf(buf, "{%}", "hello", mod) == "  hello");
	assert(bsprintf(buf, "{%1}", "hello", mod) == "  hello");
	assert(bsprintf(buf, "{0%1}", "hello", mod) == "  hello");
	assert(bsprintf(buf, "{0%2}", "hello", 0, mod) == "  hello");
	assert(bsprintf(buf, "{1%2}", 0, "hello", mod) == "  hello");
	assert(bsprintf(buf, "{2%0}", mod, 0, "hello") == "  hello");
	assert(bsprintf(buf, "{2%}", mod, 0, "hello") == "  hello");
	assert(bsprintf(buf, "|{1%}|{}|", mod, "hello") == "|  hello|hello|");
	assert(bsprintf(buf, "|{}|{2%}|", "hello", mod, "world") == "|hello|  world|");
	assert(bsprintf(buf, "|{%}|{%}|{%}|{%}|",
		"hello", &mods { ... },
		"world", &mods { width = 10, pad = ' ', ... },
		123,     &mods { prec = 10, ... },
		0xBEEF,  &mods { base = strconv::base::HEX, ... },
	) == "|hello|     world|0000000123|BEEF|");
	assert(bsprintf(buf, "|{%}|{%}|{0%1}|",
		"hello", &mods { ... },
		"world", &mods { ... },
	) == "|hello|world|hello|");

	assert(bsprintf(buf, "x: {:8X}",   0xBEEF) == "x:     BEEF");
	assert(bsprintf(buf, "x: {:8X}",  -0xBEEF) == "x:    -BEEF");
	assert(bsprintf(buf, "x: {: 8X}",  0xBEEF) == "x:     BEEF");
	assert(bsprintf(buf, "x: {:+ 8X}", 0xBEEF) == "x:     BEEF");
	assert(bsprintf(buf, "x: {:+8X}",  0xBEEF) == "x:    +BEEF");
	assert(bsprintf(buf, "x: {: +8X}", 0xBEEF) == "x:    +BEEF");

	assert(bsprintf(buf, "x: {:-8X}", 0xBEEF) == "x: BEEF    ");
	assert(bsprintf(buf, "x: {:-8X}", -0xBEEF) == "x: -BEEF   ");
	assert(bsprintf(buf, "x: {:-+8X}", 0xBEEF) == "x: +BEEF   ");
	assert(bsprintf(buf, "x: {:- 8X}", 0xBEEF) == "x:  BEEF   ");

	assert(bsprintf(buf, "x: {:.8x}", 0xBEEF) == "x: 0000beef");
	assert(bsprintf(buf, "x: {:.8x}", -0xBEEF) == "x: -000beef");
	assert(bsprintf(buf, "x: {:+.8x}", 0xBEEF) == "x: +000beef");
	assert(bsprintf(buf, "x: {: .8x}", 0xBEEF) == "x:  000beef");
	assert(bsprintf(buf, "x: {:-_08X}", 0xBEEF) == "x: BEEF0000");

	assert(bsprintf(buf, "x: {:o}", 0o755) == "x: 755");
	assert(bsprintf(buf, "x: {:b}", 0b11011) == "x: 11011");

	assert(bsprintf(buf, "x: {:8}", "hello") == "x:    hello");
	assert(bsprintf(buf, "x: {:-8}", "hello") == "x: hello   ");
	assert(bsprintf(buf, "x: {:_08}", "hello") == "x: 000hello");

	assert(bsprintf(buf, "{:.5}", "hello world") == "hello");
	assert(bsprintf(buf, "{:.5}", "hi") == "hi");
	assert(bsprintf(buf, "{:5.2}", "hello") == "   he");

	assert(bsprintf(buf, "{:.1}", 123.0) == "100");
	assert(bsprintf(buf, "{:.5}", 123.0) == "123");

	assert(bsprintf(buf, "{:f}", 1.0e4) == "10000");
	assert(bsprintf(buf, "{:e}", 123.45) == "1.2345e2");
	assert(bsprintf(buf, "{:Fs}", 1.0) == "+1");
	assert(bsprintf(buf, "{:F.}", 1.0) == "1.0");
	assert(bsprintf(buf, "{:FU}", math::INF) == "INFINITY");
	assert(bsprintf(buf, "{:FE}", 1.0e4) == "1E4");
	assert(bsprintf(buf, "{:FS}", 1.0e4) == "1e+4");
	assert(bsprintf(buf, "{:F2}", 1.0e4) == "1e04");

	assert(bsprintf(buf, "{:=5}", "hi") == "  hi ");
	assert(bsprintf(buf, "{:=6}", "hi") == "  hi  ");

	assert(bsprintf(buf, "{} {} {} {} {}", true, false, null, 'x', void)
		== "true false (null) x void");
};
