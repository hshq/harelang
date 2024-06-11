// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

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
	const buf = memio::fixed(strings::toutf8(HOSTS_FILE));
	const rd = read(&buf);
	defer finish(&rd);

	const h = next(&rd) as host;
	assert(ip::equal(h.addr, ip::LOCAL_V4));
	assert(len(h.names) == 1);
	assert(h.names[0] == "localhost");

	const h = next(&rd) as host;
	assert(ip::equal(h.addr, ip::LOCAL_V6));
	assert(len(h.names) == 2);
	assert(h.names[0] == "ip6-localhost");
	assert(h.names[1] == "ip6-loopback");

	const h = next(&rd) as host;
	assert(ip::equal(h.addr, [10, 10, 10, 10]: ip::addr4));
	assert(len(h.names) == 1);
	assert(h.names[0] == "other.localdomain");

	const h = next(&rd) as host;
	assert(ip::equal(h.addr, [10, 10, 20, 20]: ip::addr4));
	assert(len(h.names) == 1);
	assert(h.names[0] == "other.localdomain");

	const h = next(&rd);
	assert(h is done);
	const h = next(&rd);
	assert(h is done);
};

@test fn errors() void = {
	const s = "127";
	assert(next(&read(&memio::fixed(strings::toutf8(s))))
		is ip::invalid);
	const s = "127.0.0.1";
	assert(next(&read(&memio::fixed(strings::toutf8(s))))
		is invalid);
};

@test fn lookup() void = {
	const buf = memio::fixed(strings::toutf8(HOSTS_FILE));
	const rd = read(&buf);
	defer finish(&rd);

	const addrs = _lookup(&rd, "other.localdomain") as []ip::addr;
	defer free(addrs);
	assert(len(addrs) == 2);
	assert(ip::equal(addrs[0], [10, 10, 10, 10]: ip::addr4));
	assert(ip::equal(addrs[1], [10, 10, 20, 20]: ip::addr4));
};
