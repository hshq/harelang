// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use io;
use memio;
use net::ip;
use strings;

def HOSTS_FILE = `
127.0.0.1	localhost

# The following lines are desirable for IPv6 capable hosts
::1		ip6-localhost ip6-loopback

10.10.10.10	other.localdomain
10.10.20.20	other.localdomain
`;

@test fn next() void = {
	let buf = memio::fixed(strings::toutf8(HOSTS_FILE));
	let it = iter(&buf);

	const h = next(&it) as host;
	defer finish(h);
	assert(ip::equal(h.addr, ip::LOCAL_V4));
	assert(len(h.names) == 1);
	assert(h.names[0] == "localhost");

	const h = next(&it) as host;
	defer finish(h);
	assert(ip::equal(h.addr, ip::LOCAL_V6));
	assert(len(h.names) == 2);
	assert(h.names[0] == "ip6-localhost");
	assert(h.names[1] == "ip6-loopback");

	const h = next(&it) as host;
	defer finish(h);
	assert(ip::equal(h.addr, [10, 10, 10, 10]: ip::addr4));
	assert(len(h.names) == 1);
	assert(h.names[0] == "other.localdomain");

	const h = next(&it) as host;
	defer finish(h);
	assert(ip::equal(h.addr, [10, 10, 20, 20]: ip::addr4));
	assert(len(h.names) == 1);
	assert(h.names[0] == "other.localdomain");

	const h = next(&it);
	assert(h is void);
	const h = next(&it);
	assert(h is void);
};

@test fn errors() void = {
	const s = "127";
	assert(next(&iter(&memio::fixed(strings::toutf8(s))))
		is ip::invalid);
	const s = "127.0.0.1";
	assert(next(&iter(&memio::fixed(strings::toutf8(s))))
		is invalid);
};

@test fn lookup() void = {
	let buf = memio::fixed(strings::toutf8(HOSTS_FILE));
	let it = iter(&buf);
	const addrs = iter_lookup(&it, "other.localdomain") as []ip::addr;
	assert(len(addrs) == 2);
	assert(ip::equal(addrs[0], [10, 10, 10, 10]: ip::addr4));
	assert(ip::equal(addrs[1], [10, 10, 20, 20]: ip::addr4));
};
