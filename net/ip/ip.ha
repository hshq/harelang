use io;
use strio;
use fmt;
use bytes;
use rt;
use strconv;
use strings;

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

// Invalid parse result.
export type invalid = void!;

// Test if two [addr]s are equal.
export fn equal(l: addr, r: addr) bool = {
	return match (l) {
		l: addr4 => {
			if (!(r is addr4)) {
				return false;
			};
			let r = r as addr4;
			bytes::equal(l, r);
		},
		l: addr6 => {
			if (!(r is addr6)) {
				return false;
			};
			let r = r as addr6;
			bytes::equal(l, r);
		},
	};
};

export fn parsev4(st: str) (addr4 | invalid) = {
	let ret: addr4 = [0...];
	let tok = strings::tokenize(st, ".");
	let i = 0z;
	for (i < 4; i += 1) {
		let s = wanttoken(&tok)?;
		ret[i] = match (strconv::stou8(s)) {
			term: u8 => term,
			* => return invalid
		};
	};
	if (i < 4 || !(strings::next_token(&tok) is void)) {
		return invalid;
	};
	return ret;
};

fn parsev6(st: str) (addr6 | invalid) = {
	let ret: addr6 = [0...];
	let tok = strings::tokenize(st, ":");
	if (st == "::") {
		return ret;
	};
	let ells = -1;
	if (strings::has_prefix(st, "::")) {
		wanttoken(&tok)?;
		wanttoken(&tok)?;
		ells = 0;
	} else if (strings::has_prefix(st, ":")) {
		return invalid;
	};
	let i = 0;
	for (i < 16) {
		let s = match (strings::next_token(&tok)) {
			s: str => s,
			void => break,
		};
		if (s == "") {
			if (ells != -1) {
				return invalid;
			};
			ells = i;
			continue;
		};
		let val = strconv::stou16b(s, 16);
		if (val is u16) {
			let v = val as u16;
			ret[i] = (v >> 8): u8;
			i += 1;
			ret[i] = v: u8;
			i += 1;
			continue;
		} else {
			let v4 = parsev4(s)?;
			rt::memcpy(&ret[i], &v4, 4);
			i += 4;
			break;
		};
		return invalid;
	};
	if (!(strings::next_token(&tok) is void)) {
		return invalid;
	};
	if (ells >= 0) {
		if (i >= 15)
			return invalid;
		rt::memcpy(
			&ret[16 - (i - ells)],
			&ret[ells], (i - ells): size);
		rt::memset(&ret[ells], 0, (i - ells): size);
	} else {
		if (i != 16)
			return invalid;
	};

	return ret;
};


// Parses an IP address.
export fn parse(s: str) (addr | invalid) = {
	match(parsev4(s)) {
		v4: addr4 => return v4,
	};
	match(parsev6(s)) {
		v6: addr6 => return v6,
	};
	return invalid;
};

fn fmtv4(a: addr4, s: *io::stream) (io::error | size) = {
	let ret = 0z;
	for (let i = 0; i < 4; i += 1) {
		if (i > 0) {
			ret += fmt::fprintf(s, ".")?;
		};
		ret += fmt::fprintf(s, "{}", a[i])?;
	};
	return ret;
};

fn fmtv6(a: addr6, s: *io::stream) (io::error | size) = {
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

// Formats an IP address
export fn fmt(addr: addr, s: *io::stream) (io::error | size) = {
	return match (addr) {
		v4: addr4 => fmtv4(v4, s)?,
		v6: addr6 => fmtv6(v6, s)?,
	};
};

// Formats an [addr] as a string. The return value is statically
// allocated and will be overwritten on subsequent calls; see
// [strings::dup] to extend its lifetime.
export fn string(addr: addr) str = {
        // Maximum length of an IPv6 address is 45 chars
        static let buf: [46]u8 = [0...];
        let stream = strio::fixed(buf);
        fmt(addr, stream) as size;
        return strio::string(stream);
};

// Fills a netmask according to the CIDR value
// e.g. 23 -> [0xFF, 0xFF, 0xFD, 0x00]
fn fillmask(mask: []u8, val: u8) void = {
	rt::memset(&mask[0], 0xFF, len(mask));
	let i: int = len(mask): int - 1;
	val = 32 - val;
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
		addr4 => 4,
		addr6 => 16,
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
		x: u8 => x,
		* => return invalid,
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

fn fmtmask(mask: addr, s: *io::stream) (io::error | size) = {
	let ret = 0z;
	let slice = match (mask) {
		v4: addr4 => v4[..],
		v6: addr6 => v6[..],
	};
	match (masklen(slice)) {
		// format as hex, if zero runs are not contiguous
		// (like golang does)
		void => {
			for (let i = 0z; i < len(slice); i += 1) {
				ret += fmt::fprintf(s, "{:x}", slice[i])?;
			};
		},
		// standard CIDR integer
		n: size => ret += fmt::fprintf(s, "{}", n)?,
	};
	return ret;
};

// Format an IP subnet
export fn fmtsubnet(subnet: subnet, s: *io::stream) (io::error | size) = {
	let ret = 0z;
	ret += fmt(subnet.addr, s)?;
	ret += fmt::fprintf(s, "/")?;
	ret += fmtmask(subnet.mask, s)?;
	return ret;
};

// Formats a [subnet] as a string. The return value is statically
// allocated and will be overwritten on subsequent calls; see
// [strings::dup] to extend its lifetime.
export fn stringsubnet(subnet: subnet) str = {
        static let buf: [66]u8 = [0...];
        let stream = strio::fixed(buf);
        fmtsubnet(subnet, stream) as size;
        return strio::string(stream);
};

fn wanttoken(tok: *strings::tokenizer) (str | invalid) = {
	return match (strings::next_token(tok)) {
		s: str => s,
		void => invalid
	};
};
