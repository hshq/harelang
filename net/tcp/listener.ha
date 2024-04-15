// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use net;

// Accepts the next connection from a socket. Blocks until a new connection is
// available. This is a convenience wrapper around [[net::accept]].
export fn accept(
	sock: net::socket,
	flags: net::sockflag,
) (net::socket | net::error) = net::accept(sock, flags);
