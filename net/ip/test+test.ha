// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use strings;

fn ip_test(s: str, expected: (addr|invalid)) void = {
	let pr = parse(s);
	let ip = if (pr is invalid) {
		assert(expected is invalid);
		return;
	} else {
		assert(expected is addr);
		assert(equal(pr as addr, expected as addr));
		yield pr as addr;
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
		("0.011.001.000", invalid),
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
	for (let (string, expected) .. tests) {
		ip_test(string, expected);
	};
};

fn subnet_test_simple(s: str) void = {
	let net = match (parsecidr(s)) {
	case let a: subnet =>
		yield a;
	case =>
		return;
	};
	let fmted = string(net);
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
	for (let test .. subnet_tests) {
		subnet_test_simple(test);
	};
};

@test fn test_subnet_contains() void = {
	let addr_tests: [](str, str, bool) = [
		// a, b, want
		("10.10.10.0/24", "10.10.10.0",   true),
		("10.10.10.0/24", "10.10.10.255", true),
		("10.10.10.0/24", "10.10.11.0",   false),
		("127.0.0.1/24",  "::1",          false),
		("::1/8",         "::1",          true),
	];
	let cidr_tests: [](str, str, bool) = [
		// a, b, want
		("10.10.10.0/24", "10.10.10.0/24", true),
		("10.10.10.0/24", "10.10.10.0/25", true),
		("10.10.10.0/24", "10.10.10.0/23", false),
		("10.10.10.0/24", "10.10.11.0/24", false),
	];
	for (let (a, b, want) .. addr_tests) {
		let a = parsecidr(a)!;
		let b = parse(b)!;
		assert(subnet_contains(a, b) == want);
	};
	for (let (a, b, want) .. cidr_tests) {
		let a = parsecidr(a)!;
		let b = parsecidr(b)!;
		assert(subnet_contains(a, b) == want);
	};
};
