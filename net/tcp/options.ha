// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use net;

// Enables keep-alive for a socket.
export type keepalive = void;

// Configures the backlog size for a listener. If not specified, a sensible
// default (10) is used.
export type backlog = u32;

// Enables port re-use for a TCP listener.
export type reuseport = void;

// Enables address re-use for a TCP listener.
export type reuseaddr = void;

// To have the system select an arbitrary unused port for [[listen]], set port to
// zero. To retrieve the assigned port, provide this as one of the options and
// the addressed u16 will be filled in with the port.
export type portassignment = *u16;

// Options for [[connect]].
export type connect_option = (keepalive | net::sockflag);

// Options for [[listen]].
export type listen_option = (
	keepalive |
	reuseport |
	reuseaddr |
	backlog |
	portassignment |
	net::sockflag);
