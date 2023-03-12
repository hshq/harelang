// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use net;

// Enables port re-use for a UDP listener.
export type reuseport = void;

// Enables address re-use for a UDP listener.
export type reuseaddr = void;

// To have the system select an arbitrary unused port for [[listen]], set port to
// zero. To retrieve the assigned port, provide this as one of the options and
// the addressed u16 will be filled in with the port.
export type portassignment = *u16;

// Options for [[connect]].
export type connect_option = net::sockflags;

// Options available for [[listen]].
export type listen_option = (
	reuseport |
	reuseaddr |
	portassignment |
	net::sockflags);

// TODO: Add send/recv flags
