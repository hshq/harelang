// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use crypto::random;
use net::dns;
use net::ip;
use strconv;
use strings;
use unix::hosts;

// Splits an address:port/service string into separate address and port
// components. The return value is borrowed from the input.
export fn splitaddr(addr: str, service: str) ((str, u16) | invalid_address) = {
	let port = 0u16;
	if (strings::hasprefix(addr, '[')) {
		// [::1]:80 (IPv6)
		match (strings::index(addr, "]:")) {
		case let i: size =>
			const sub = strings::sub(addr, i + 2, strings::end);
			addr = strings::sub(addr, 1, i);
			match (strconv::stou16(sub)) {
			case let u: u16 =>
				port = u;
			case =>
				return invalid_address;
			};
		case void =>
			match (strconv::stou16(service)) {
			case let u: u16 =>
				port = u;
			case => void;
			};
		};
		return (addr, port);
	};

	// 1.1.1.1:80 (IPv4)
	match (strings::index(addr, ':')) {
	case void =>
		match (strconv::stou16(service)) {
		case let u: u16 =>
			port = u;
		case => void;
		};
	case let i: size =>
		const sub = strings::sub(addr, i + 1, strings::end);
		addr = strings::sub(addr, 0, i);
		match (strconv::stou16(sub)) {
		case let u: u16 =>
			port = u;
		case =>
			return invalid_address;
		};
	};
	return (addr, port);
};

// Performs DNS resolution on a given address string for a given service,
// including /etc/hosts lookup and SRV resolution, and returns a list of
// candidate IP addresses and the appropriate port, or an error.
//
// The caller must free the [[net::ip::addr]] slice.
export fn resolve(
	proto: str,
	addr: str,
	service: str,
) (([]ip::addr, u16) | error) = {
	const (addr, port) = splitaddr(addr, service)?;
	if (service == "unknown" && port == 0) {
		return unknown_service;
	};

	let addrs = resolve_addr(addr)?;
	if (port == 0) match (lookup_service(proto, service)) {
	case let p: u16 =>
		port = p;
	case void => void;
	};

	// TODO:
	// - Consult /etc/services
	// - Fetch the SRV record

	if (port == 0) {
		return unknown_service;
	};
	if (len(addrs) == 0) {
		return dns::name_error;
	};

	return (addrs, port);
};

fn resolve_addr(addr: str) ([]ip::addr | error) = {
	match (ip::parse(addr)) {
	case let addr: ip::addr =>
		return alloc([addr]);
	case ip::invalid => void;
	};

	const addrs = hosts::lookup(addr)?;
	if (len(addrs) != 0) {
		return addrs;
	};

	const domain = dns::parse_domain(addr);
	defer free(domain);

	let rand: []u8 = [0, 0];
	random::buffer(rand);
	let id = *(&rand[0]: *u16);

	const query6 = dns::message {
		header = dns::header {
			id = id,
			op = dns::op {
				qr = dns::qr::QUERY,
				opcode = dns::opcode::QUERY,
				rd = true,
				...
			},
			qdcount = 1,
			...
		},
		questions = [
			dns::question {
				qname = domain,
				qtype = dns::qtype::AAAA,
				qclass = dns::qclass::IN,
			},
		],
		...
	};
	const query4 = dns::message {
		header = dns::header {
			id = id + 1,
			op = dns::op {
				qr = dns::qr::QUERY,
				opcode = dns::opcode::QUERY,
				rd = true,
				...
			},
			qdcount = 1,
			...
		},
		questions = [
			dns::question {
				qname = domain,
				qtype = dns::qtype::A,
				qclass = dns::qclass::IN,
			},
		],
		...
	};

	const resp6 = dns::query(&query6)?;
	defer dns::message_free(resp6);
	const resp4 = dns::query(&query4)?;
	defer dns::message_free(resp4);

	let addrs: []ip::addr = [];
	collect_answers(&addrs, &resp6.answers);
	collect_answers(&addrs, &resp4.answers);
	return addrs;
};

fn collect_answers(addrs: *[]ip::addr, answers: *[]dns::rrecord) void = {
	for (let i = 0z; i < len(answers); i += 1) {
		match (answers[i].rdata) {
		case let addr: dns::aaaa =>
			append(addrs, addr: ip::addr);
		case let addr: dns::a =>
			append(addrs, addr: ip::addr);
		case => void;
		};
	};
};
