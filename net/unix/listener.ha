// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use net;

// Accepts the next connection from a socket. Blocks until a new connection is
// available. This is a convenience wrapper around [[net::accept]].
export fn accept(
	sock: net::socket,
	flags: net::sockflags...
) (net::socket | net::error) = net::accept(sock, flags...);

// Shuts down a listening socket. This is a convenience wrapper around
// [[net::shutdown]].
export fn shutdown(sock: net::socket) void = net::shutdown(sock);
