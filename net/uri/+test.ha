// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use fmt;
use net::ip;

@test fn roundtrip() void = {
	test_uri_roundtrip(
		"file:///my/path/to/file",
		uri {
			scheme = "file",
			host = "",
			path = "/my/path/to/file",
			...
		},
	)!;
	test_uri_roundtrip(
		"http://harelang.org/",
		uri {
			scheme = "http",
			host = "harelang.org",
			path = "/",
			...
		},
	)!;
	test_uri_roundtrip(
		"irc+insecure://chat.sr.ht:6667",
		uri {
			scheme = "irc+insecure",
			host = "chat.sr.ht",
			port = 6667,
			...
		},
	)!;
	test_uri_roundtrip(
		"ldap://13.37.73.31:1234/",
		uri {
			scheme = "ldap",
			host = [13, 37, 73, 31]: ip::addr4,
			port = 1234,
			path = "/",
			...
		},
	)!;
	test_uri_roundtrip(
		"http://[::1]/test",
		uri {
			scheme = "http",
			host = ip::parse("::1")!,
			path = "/test",
			...
		},
	)!;

	// Some non-URL variants like mailto: or URN
	test_uri_roundtrip(
		"urn:example:animal:ferret:nose",
		uri {
			scheme = "urn",
			host = "",
			path = "example:animal:ferret:nose",
			...
		},
	)!;
	test_uri_roundtrip(
		"mailto:~sircmpwn/hare-dev@lists.sr.ht",
		uri {
			scheme = "mailto",
			host = "",
			path = "~sircmpwn/hare-dev@lists.sr.ht",
			...
		},
	)!;
	test_uri_roundtrip(
		"https://sr.ht/projects?search=%23risc-v&sort=longest-active#foo",
		uri {
			scheme = "https",
			host = "sr.ht",
			path = "/projects",
			query = "search=%23risc-v&sort=longest-active",
			fragment = "foo",
			...
		},
	)!;
	test_uri_roundtrip(
		"https://en.wiktionary.org/wiki/%E3%81%8A%E3%81%AF%E3%82%88%E3%81%86#Japanese",
		uri {
			scheme = "https",
			host = "en.wiktionary.org",
			path = "/wiki/おはよう",
			fragment = "Japanese",
			...
		}
	)!;
};

@test fn invalid() void = {
	// Scheme
	assert(parse(":") is invalid);
	assert(parse("hello*:") is invalid);
	assert(parse("hello") is invalid);

	// Unexpected character
	assert(parse("https://^harelang.org") is invalid);

	// Something other than IPv6 address inside [ ... ]
	assert(parse("https://[1.2.3.4]") is invalid);
	assert(parse("https://[example]") is invalid);

	// '@' in userinfo
	assert(parse("https://a@b@example") is invalid);
	assert(parse("https://@@example") is invalid);
};

@test fn percent_encoding() void = {
	test_uri(
		"https://git%2esr.ht/~sircmpw%6e/hare#Build%20status",
		uri {
			scheme = "https",
			host = "git.sr.ht",
			path = "/~sircmpwn/hare",
			fragment = "Build status",
			...
		},
		"https://git.sr.ht/~sircmpwn/hare#Build%20status",
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
		"ldap://[2001:db8::7]/c=GB?objectClass?one",
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
		"https://web-safety.net/..;@www.google.com:443",
	)!;
};

fn test_uri_roundtrip(in: str, expected: uri) (void | invalid) = {
	test_uri(in, expected, in)?;
};

fn test_uri(in: str, expected_uri: uri, expected_str: str) (void | invalid) = {
	const u = parse(in)?;
	defer finish(&u);

	assert_str(u.scheme, expected_uri.scheme);
	match (u.host) {
	case let s: str =>
		assert_str(s, expected_uri.host as str);
	case let i: ip::addr =>
		assert(ip::equal(i, expected_uri.host as ip::addr));
	};
	assert(u.port == expected_uri.port);
	assert_str(u.userinfo, expected_uri.userinfo);
	assert_str(u.path, expected_uri.path);
	assert_str(u.query, expected_uri.query);
	assert_str(u.fragment, expected_uri.fragment);

	const s = string(&u);
	defer free(s);

	assert_str(s, expected_str);
};

fn assert_str(got: str, expected: str) void = {
	if (got != expected) {
		fmt::errorfln("=== wanted\n{}", expected)!;
		fmt::errorfln("=== got\n{}", got)!;
		abort();
	};
};
