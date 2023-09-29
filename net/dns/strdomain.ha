// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use strings;

// Converts a human-readable domain name (e.g. "example.org") into a DNS-ready
// name slice (e.g. ["example", "org"]). The slice returned must be freed by the
// caller, but the members of the slice themselves are borrowed from the input.
export fn parse_domain(in: str) []str = strings::split(in, ".");

// Converts a DNS name slice (e.g. ["example", "org"]) into a human-readable
// domain name (e.g. "example.org"). The return value must be freed by the
// caller.
export fn unparse_domain(in: []str) str = strings::join(".", in...);
