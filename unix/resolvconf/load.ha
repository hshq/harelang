// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use bufio;
use fmt;
use io;
use memio;
use net::ip;
use os;
use strings;

let cache_valid = false;
let cache: config = config {
	options = DEFAULT_OPTIONS,
	...
};

@fini fn fini() void = {
	if (!cache_valid) {
		return;
	};

	strings::freeall(cache.search);
	free(cache.nameservers);
	free(cache.sortlist);
};

// Reads /etc/resolv.conf (or the platform-specific equivalent path) and returns
// the configuration therein. If the file does not exist, or is poorly
// formatted, returns the default resolver configuration.
export fn load() *config = {
	if (cache_valid) {
		return &cache;
	};

	const file = match (os::open("/etc/resolv.conf")) {
	case let file: io::file =>
		yield file;
	case =>
		cache_valid = true;
		return &cache;
	};
	defer io::close(file)!;

	match (parse(&cache, file)) {
	case let err: error =>
		fmt::errorfln("Error parsing /etc/resolv.conf: {}",
			strerror(err)): void;
		return &cache;
	case void =>
		cache_valid = true;
		return &cache;
	};
};

// Parses a resolv.conf-formatted file and populates the given config object.
fn parse(conf: *config, in: io::handle) (void | error) = {
	const rd = read(in);
	for (const param => next(&rd)!) {
		switch (param.name) {
		case "nameserver" =>
			append(conf.nameservers, param.value as ip::addr);
		case "search" =>
			strings::freeall(conf.search);
			conf.search = strings::dupall(param.value as []str);
		case "sortlist" =>
			free(conf.sortlist);
			conf.sortlist = alloc((param.value as []ip::subnet)...);
		case "options" =>
			conf.options = *(param.value as *options);
		case => void;
		};
	};
};
