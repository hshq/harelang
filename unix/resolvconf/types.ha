// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use net::ip;

// A list of [[net::ip::subnet]]s.
export type subnet_list = []ip::subnet;

// Values set in an "options" directive.
export type options = struct {
	debug: bool,
	ndots: uint,
	timeout: uint,
	attempts: uint,
	rotate: bool,
	no_aaaa: bool,
	no_check_names: bool,
	inet6: bool,
	edns0: bool,
	single_request: bool,
	single_request_reopen: bool,
	no_tld_query: bool,
	use_vc: bool,
	no_reload: bool,
	trust_ad: bool,
};

def DEFAULT_OPTIONS = options {
	ndots = 1,
	timeout = 5,
	attempts = 2,
	...
};

// The value associated with a configuration parameter.
export type value = (ip::addr | subnet_list | *options | []str);

// A configuration parameter from resolv.conf.
export type parameter = struct {
	name: const str,
	value: value,
};

// A complete configuration parsed from resolv.conf.
export type config = struct {
	nameservers: []ip::addr,
	search: []str,
	sortlist: []ip::subnet,
	options: options,
};
