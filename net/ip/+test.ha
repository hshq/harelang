use strings;
use fmt;

fn ip_test(s: str, expected: (addr|invalid)) void = {
	let pr = parse(s);
	let ip = if (pr is invalid) {
		assert(expected is invalid);
		return;
	} else {
		assert(expected is addr);
		assert(equal(pr as addr, expected as addr));
		pr as addr;
	};
	let fmted = string(ip);
	let iprp = parse(fmted);
	assert(iprp is addr);
	let ipr = iprp as addr;
	assert(equal(ip, ipr));
	if (ip is addr4) {
		assert(fmted == s);
	} else {
		assert(strings::dup(fmted) == string(ipr));
	};
};

@test fn parse_ip() void = {
	let tests: [](str, (addr|invalid)) = [
		("127.0.0.1", [127, 0, 0, 1]: addr4),
		("192.168.18.1", [192, 168, 18, 1]: addr4),
		("-127.0.0.1", invalid),
		("127.-0.0.1", invalid),
		("::", [0...]: addr6),
		("::1", [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1]: addr6),
		("::FFFF:FFFF", [0,0,0,0,0,0,0,0,0,0,0,0,0xFF,0xFF,0xFF,0xFF]: addr6),
		("::FFFF", [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0xFF,0xFF]: addr6),
		(":FFFF", invalid),
		("::1:1", [0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1]: addr6),
		("1::1", [0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1]: addr6),
		(":::1:1", invalid),
		(":::", invalid),
		("::1::1", invalid),
		("1::::1", invalid),
		("FFFF::FFFF::1", invalid),
		("::127.0.0.1", [0,0,0,0,0,0,0,0,0,0,0,0,127,0,0,1]: addr6),
		("FFFF:FFFF", invalid),
		("DEAD::BEef", [0xDE, 0xAD, 0,0,0,0,0,0,0,0,0,0,0,0, 0xBE, 0xEF]: addr6),
		("DEAD::BEef:A12D", [0xDE, 0xAD, 0,0,0,0,0,0,0,0,0,0, 0xBE, 0xEF, 0xA1, 0x2D]: addr6),
		("DEAD:BEef::0102:A12D", [0xDE, 0xAD,0xBE,0xEF,0,0,0,0,0,0,0,0,0x01,0x02,0xA1,0x2D]: addr6),
		("DEAD:BEef:::A12D", invalid),
		("1980:cafe:a:babe::1", [0x19, 0x80, 0xca, 0xfe, 0x0, 0xa, 0xba, 0xbe, 0, 0, 0, 0, 0, 0, 0, 1]: addr6),
		("a1:a2:a3:a4::b1:b2:b3:b4", invalid),
		("", invalid),
	];
	for (let i = 0z; i < len(tests); i += 1) {
		ip_test(tests[i].0, tests[i].1);
	};
};

fn subnet_test_simple(s: str) void = {
	let net = match (parsecidr(s)) {
		a: subnet => a,
		* => return,
	};
	let fmted = stringsubnet(net);
	assert(fmted == s);
	let netrp = parsecidr(fmted);
	assert(netrp is subnet);
	let netr = netrp as subnet;
	assert(equal(net.addr, netr.addr));
	assert(equal(net.mask, netr.mask));
};

@test fn parse_subnet() void = {
	let subnet_tests: []str = [
		"192.168.1.0/0",
		"192.168.1.0/23",
		"192.168.1.0/24",
		"192.168.1.0/32",
	];
	for (let i = 0z; i < len(subnet_tests); i += 1) {
		subnet_test_simple(subnet_tests[i]);
	};
};
