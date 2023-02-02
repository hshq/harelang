// License: MPL-2.0
// (c) 2022 Alexey Yerin <yyp@disroot.org>
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Byron Torres <b@torresjrjr.com>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
// (c) 2021 Miccah Castorina <contact@miccah.io>
// (c) 2021 Mykyta Holubakha <hilobakho@gmail.com>
// (c) 2021 Thomas Bracht Laumann Jespersen <t@laumann.xyz>
use bytes;
use endian;
use fmt;
use io;
use strconv;
use strings;
use strio;

// An IPv4 address.
export type addr4 = [4]u8;

// An IPv6 address.
export type addr6 = [16]u8;

// An IP address.
export type addr = (addr4 | addr6);

// An IP subnet.
export type subnet = struct {
	addr: addr,
	mask: addr,
};

// An IPv4 address which represents "any" address, i.e. "0.0.0.0". Binding to
// this address will listen on all available IPv4 interfaces on most systems.
export const ANY_V4: addr4 = [0, 0, 0, 0];

// An IPv6 address which represents "any" address, i.e. "::". Binding to this
// address will listen on all available IPv6 interfaces on most systems.
export const ANY_V6: addr6 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

// An IPv4 address which represents the loopback address, i.e. "127.0.0.1".
export const LOCAL_V4: addr4 = [127, 0, 0, 1];

// An IPv6 address which represents the loopback address, i.e. "::1".
export const LOCAL_V6: addr6 = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1];

// Invalid parse result.
export type invalid = !void;

// Test if two [[addr]]s are equal.
export fn equal(l: addr, r: addr) bool = {
	match (l) {
	case let l: addr4 =>
		if (!(r is addr4)) {
			return false;
		};
		let r = r as addr4;
		return bytes::equal(l, r);
	case let l: addr6 =>
		if (!(r is addr6)) {
			return false;
		};
		let r = r as addr6;
		return bytes::equal(l, r);
	};
};

fn parsev4(st: str) (addr4 | invalid) = {
	let ret: addr4 = [0...];
	let tok = strings::tokenize(st, ".");
	let i = 0z;
	for (i < 4; i += 1) {
		let s = wanttoken(&tok)?;
		if (len(s) != 1 && strings::hasprefix(s, "0")) {
			return invalid;
		};
		ret[i] = match (strconv::stou8(s)) {
		case let term: u8 =>
			yield term;
		case =>
			return invalid;
		};
	};
	if (i < 4 || !(strings::next_token(&tok) is void)) {
		return invalid;
	};
	return ret;
};

fn parsev6(st: str) (addr6 | invalid) = {
	let ret: addr6 = [0...];
	if (st == "::") {
		return ret;
	};
	let tok = strings::tokenize(st, ":");
	let ells = -1;
	if (strings::hasprefix(st, "::")) {
		wanttoken(&tok)?;
		wanttoken(&tok)?;
		ells = 0;
	} else if (strings::hasprefix(st, ":")) {
		return invalid;
	};
	let i = 0;
	for (i < 16) {
		let s = match (strings::next_token(&tok)) {
		case let s: str =>
			yield s;
		case void =>
			break;
		};
		if (s == "") {
			if (ells != -1) {
				return invalid;
			};
			ells = i;
			continue;
		};
		match (strconv::stou16b(s, 16)) {
		case let val: u16 =>
			endian::beputu16(ret[i..], val);
			i += 2;
		case =>
			ret[i..i + 4] = parsev4(s)?;
			i += 4;
			break;
		};
	};
	if (!(strings::next_token(&tok) is void)) {
		return invalid;
	};
	if (ells >= 0) {
		if (i >= 15) {
			return invalid;
		};
		const n = i - ells;
		ret[16 - n..16] = ret[ells..ells + n];
		ret[ells..ells + n] = [0...];
	} else if (i != 16) {
		return invalid;
	};

	return ret;
};


// Parses an IP address.
export fn parse(s: str) (addr | invalid) = {
	match (parsev4(s)) {
	case let v4: addr4 =>
		return v4;
	case invalid => void;
	};
	match (parsev6(s)) {
	case let v6: addr6 =>
		return v6;
	case invalid => void;
	};
	return invalid;
};

fn fmtv4(s: io::handle, a: addr4) (io::error | size) = {
	let ret = 0z;
	for (let i = 0; i < 4; i += 1) {
		if (i > 0) {
			ret += fmt::fprintf(s, ".")?;
		};
		ret += fmt::fprintf(s, "{}", a[i])?;
	};
	return ret;
};

fn fmtv6(s: io::handle, a: addr6) (io::error | size) = {
	let ret = 0z;
	let zstart: int = -1;
	let zend: int = -1;
	for (let i = 0; i < 16; i += 2) {
		let j = i;
		for (j < 16 && a[j] == 0 && a[j + 1] == 0) {
			j += 2;
		};

		if (j > i && j - i > zend - zstart) {
			zstart = i;
			zend = j;
			i = j;
		};
	};

	if (zend - zstart <= 2) {
		zstart = -1;
		zend = -1;
	};

	for (let i = 0; i < 16; i += 2) {
		if (i == zstart) {
			ret += fmt::fprintf(s, "::")?;
			i = zend;
			if (i >= 16)
				break;
		} else if (i > 0) {
			ret += fmt::fprintf(s, ":")?;
		};
		let term = (a[i]: u16) << 8 | a[i + 1];
		ret += fmt::fprintf(s, "{:x}", term)?;
	};
	return ret;
};

// Fills a netmask according to the CIDR value
// e.g. 23 -> [0xFF, 0xFF, 0xFD, 0x00]
fn fillmask(mask: []u8, val: u8) void = {
	mask[..] = [0xFF...];
	let i: int = len(mask): int - 1;
	val = len(mask): u8 * 8 - val;
	for (val >= 8) {
		mask[i] = 0x00;
		val -= 8;
		i -= 1;
	};
	if (i >= 0) {
		mask[i] = ~((1 << val) - 1);
	};
};

// Returns an addr representing a netmask
fn cidrmask(addr: addr, val: u8) (addr | invalid) = {
	let a_len: u8 = match (addr) {
	case addr4 =>
		yield 4;
	case addr6 =>
		yield 16;
	};

	if (val > 8 * a_len)
		return invalid;
	if (a_len == 4) {
		let ret: addr4 = [0...];
		fillmask(ret[..], val);
		return ret;
	};
	if (a_len == 16) {
		let ret: addr6 = [0...];
		fillmask(ret[..], val);
		return ret;
	};
	return invalid;
};

// Parse an IP subnet in CIDR notation e.g. 192.168.1.0/24
export fn parsecidr(st: str) (subnet | invalid) = {
	let tok = strings::tokenize(st, "/");
	let ips = wanttoken(&tok)?;
	let addr = parse(ips)?;
	let masks = wanttoken(&tok)?;
	let val = match (strconv::stou8(masks)) {
	case let x: u8 =>
		yield x;
	case =>
		return invalid;
	};
	if (!(strings::next_token(&tok) is void)) {
		return invalid;
	};
	return subnet {
		addr = addr,
		mask = cidrmask(addr, val)?
	};
};

fn masklen(addr: []u8) (void | size) = {
	let n = 0z;
	for (let i = 0z; i < len(addr); i += 1) {
		if (addr[i] == 0xff) {
			n += 8;
			continue;
		};
		let val = addr[i];
		for (val & 0x80 != 0) {
			n += 1;
			val <<= 1;
		};
		if (val != 0)
			return;
		for (let j = i + 1; j < len(addr); j += 1) {
			if (addr[j] != 0)
				return;
		};
		break;
	};
	return n;
};

fn fmtmask(s: io::handle, mask: addr) (io::error | size) = {
	let ret = 0z;
	let slice = match (mask) {
	case let v4: addr4 =>
		yield v4[..];
	case let v6: addr6 =>
		yield v6[..];
	};
	match (masklen(slice)) {
	case void =>
		// Format as hex, if zero runs are not contiguous
		// (like golang does)
		for (let i = 0z; i < len(slice); i += 1) {
			ret += fmt::fprintf(s, "{:x}", slice[i])?;
		};
	case let n: size =>
		// Standard CIDR integer
		ret += fmt::fprintf(s, "{}", n)?;
	};
	return ret;
};

fn fmtsubnet(s: io::handle, subnet: subnet) (io::error | size) = {
	let ret = 0z;
	ret += fmt(s, subnet.addr)?;
	ret += fmt::fprintf(s, "/")?;
	ret += fmtmask(s, subnet.mask)?;
	return ret;
};

// Formats an [[addr]] or [[subnet]] and prints it to a stream.
export fn fmt(s: io::handle, item: (...addr | subnet)) (io::error | size) = {
	match (item) {
	case let v4: addr4 =>
		return fmtv4(s, v4)?;
	case let v6: addr6 =>
		return fmtv6(s, v6)?;
	case let sub: subnet =>
		return fmtsubnet(s, sub);
	};
};

// Formats an [[addr]] or [[subnet]] as a string. The return value is statically
// allocated and will be overwritten on subsequent calls; see [[strings::dup]] to
// extend its lifetime.
export fn string(item: (...addr | subnet)) str = {
	// Maximum length of an IPv6 address plus its netmask in hexadecimal
	static let buf: [64]u8 = [0...];
	let stream = strio::fixed(buf);
	fmt(&stream, item) as size;
	return strio::string(&stream);
};

fn wanttoken(tok: *strings::tokenizer) (str | invalid) = {
	match (strings::next_token(tok)) {
	case let s: str =>
		return s;
	case void =>
		return invalid;
	};
};

// Returns whether an [[addr]] (or another [[subnet]]) is contained
// within a [[subnet]].
export fn subnet_contains(sub: subnet, item: (addr | subnet)) bool = {
	let a: subnet = match (item) {
	case let a: addr =>
		yield subnet {
			addr = a,
			mask = sub.mask,
		};
	case let sub: subnet =>
		yield sub;
	};
	// Get byte slices for both addresses and masks.
	let ipa = match (sub.addr) {
		case let v4: addr4 => yield v4[..];
		case let v6: addr6 => yield v6[..];
	};
	let maska = match (sub.mask) {
		case let v4: addr4 => yield v4[..];
		case let v6: addr6 => yield v6[..];
	};
	let ipb = match (a.addr) {
		case let v4: addr4 => yield v4[..];
		case let v6: addr6 => yield v6[..];
	};
	let maskb = match (a.mask) {
		case let v4: addr4 => yield v4[..];
		case let v6: addr6 => yield v6[..];
	};
	if (len(ipa) != len(ipb) || len(maska) != len(maskb) || len(ipa) != len(maska)) {
		// Mismatched addr4 and addr6 addresses / masks.
		return false;
	};
	for (let i = 0z; i < len(ipa); i += 1) {
		if (ipa[i] & maska[i] != ipb[i] & maska[i] || maska[i] > maskb[i]) {
			return false;
		};
	};
	return true;
};
