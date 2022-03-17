use net::ip;

@test fn parse() void = {
	test_uri(
		"http://harelang.org/",
		uri {
			scheme = "http",
			host = "harelang.org",
			path = "/",
			...
		},
	)!;
	test_uri(
		"irc+insecure://chat.sr.ht:6667",
		uri {
			scheme = "irc+insecure",
			host = "chat.sr.ht",
			port = 6667,
			...
		},
	)!;
	test_uri(
		"ldap://13.37.73.31:1234/",
		uri {
			scheme = "ldap",
			host = [13, 37, 73, 31]: ip::addr4,
			port = 1234,
			path = "/",
			...
		},
	)!;
	test_uri(
		"http://[::1]/test",
		uri {
			scheme = "http",
			host = ip::parse("::1")!,
			path = "/test",
			...
		},
	)!;

	// Test percent decoding in various places
	test_uri(
		"https://git%2esr.ht/~sircmpw%6e/hare#Build%20status",
		uri {
			scheme = "https",
			host = "git.sr.ht",
			path = "/~sircmpwn/hare",
			fragment = "Build status",
			...
		},
	)!;

	// IPv6
	test_uri(
		"ldap://[2001:db8::7]/c=GB?objectClass?one",
		uri {
			scheme = "ldap",
			host = ip::parse("2001:db8::7")!,
			path = "/c=GB",
			query = "objectClass?one",
			...
		},
	)!;

	// Some non-URL variants like mailto: or URN
	test_uri(
		"urn:example:animal:ferret:nose",
		uri {
			scheme = "urn",
			host = "",
			path = "example:animal:ferret:nose",
			...
		},
	)!;
	test_uri(
		"mailto:~sircmpwn/hare-dev@lists.sr.ht",
		uri {
			scheme = "mailto",
			host = "",
			path = "~sircmpwn/hare-dev@lists.sr.ht",
			...
		},
	)!;

	// https://bugs.chromium.org/p/chromium/issues/detail?id=841105
	test_uri(
		"https://web-safety.net/..;@www.google.com:%3443",
		uri {
			scheme = "https",
			host = "web-safety.net",
			path = "/..;@www.google.com:443",
			...
		},
	)!;
};

@test fn invalid() void = {
	// Scheme
	assert(parse(":") is invalid);
	assert(parse("hello*:") is invalid);
	assert(parse("hello") is invalid);
};

fn test_uri(in: str, expected: uri) (void | invalid) = {
	const u = parse(in)?;
	defer finish(&u);

	assert(u.scheme == expected.scheme);
	match (u.host) {
	case let s: str =>
		assert(s == expected.host as str);
	case let i: ip::addr =>
		assert(ip::equal(i, expected.host as ip::addr));
	};
	assert(u.port == expected.port);
	assert(u.userinfo == expected.userinfo);
	assert(u.path == expected.path);
	assert(u.query == expected.query);
	assert(u.fragment == expected.fragment);
};
