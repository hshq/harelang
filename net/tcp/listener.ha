// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use io;
use net;

// Accepts the next connection from a socket. Blocks until a new connection is
// available. This is a convenience wrapper around [[net::accept]].
export fn accept(sock: io::file) (io::file | net::error) = net::accept(sock);

// Shuts down a listening socket. This is a convenience wrapper around
// [[net::shutdown]].
export fn shutdown(sock: io::file) void = net::shutdown(sock);
