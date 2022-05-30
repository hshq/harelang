use ascii;
use encoding::utf8;
use fmt;
use io;
use net::ip;
use strconv;
use strings;
use strio;

// Writes a formatted [[uri]] to an [[io::handle]]. Returns the number of bytes
// written.
export fn fmt(out: io::handle, u: *const uri) (size | io::error) = {
	let n = 0z;
	let slashes_w = false;
	n += fmt::fprintf(out, "{}:", u.scheme)?;
	if (len(u.userinfo) > 0) {
		assert(!(u.host is str) || len(u.host as str) > 0);
		n += fmt::fprintf(out, "//{}@", u.userinfo)?;
		slashes_w = true;
	};
	match (u.host) {
	case let host: str =>
		// file scheme is allowed an empty host
		if (len(host) > 0 || u.scheme == "file") {
			if (!slashes_w) {
				n += fmt::fprint(out, "//")?;
			};
			n += percent_encode(out, host)?;
		};
	case let addr: ip::addr =>
		if (!slashes_w) {
			n += fmt::fprint(out, "//")?;
		};
		n += fmtaddr(out, addr)?;
	};
	if (u.port != 0) {
		n += fmt::fprintf(out, ":{}", u.port)?;
	};
	n += fmt::fprint(out, u.path)?;
	if (len(u.query) > 0) {
		n += fmt::fprint(out, "?")?;
		n += percent_encode(out, u.query)?;
	};
	if (len(u.fragment) > 0) {
		n += fmt::fprint(out, "#")?;
		n += percent_encode(out, u.fragment)?;
	};

	return n;
};

fn fmtaddr(out: io::handle, addr: ip::addr) (size | io::error) = {
	let n = 0z;
	match (addr) {
	case let addr: ip::addr4 =>
		n += ip::fmt(out, addr)?;
	case let addr: ip::addr6 =>
		n += fmt::fprintf(out, "[")?;
		n += ip::fmt(out, addr)?;
		n += fmt::fprintf(out, "]")?;
	};
	return n;
};

fn percent_encode(out: io::handle, src: str) (size | io::error) = {
	let iter = strings::iter(src);
	let n = 0z;
	for (true) {
		const r = match (strings::next(&iter)) {
		case let r: rune =>
			yield r;
		case =>
			break;
		};
		// unreserved
		if (ascii::isalnum(r) || strings::contains("-._~", r)) {
			n += fmt::fprint(out, r)?;
		} else {
			const en = utf8::encoderune(r);
			for (let i = 0z; i < len(en); i += 1) {
				n += fmt::fprintf(out, "%{}",
					strconv::u8tosb(en[i],
						strconv::base::HEX))?;
			};
		};
	};
	return n;
};

// Formats a [[uri]] into a string. The result must be freed by the caller.
export fn string(u: *const uri) str = {
	const st = strio::dynamic();
	fmt(&st, u)!;
	return strio::string(&st);
};
