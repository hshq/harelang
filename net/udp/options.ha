// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>

// To have the system select an arbitrary unused port for [[listen]], set port to
// zero. To retrieve the assigned port, provide this as one of the options and
// the addressed u16 will be filled in with the port.
export type portassignment = *u16;

// Options available for [[listen]].
export type listen_option = portassignment;

// TODO: Add send/recv flags
