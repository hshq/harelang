// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use net;

// Configures the backlog size for a listener. If not specified, a sensible
// default (10) is used.
export type backlog = u32;

// Options for [[connect]].
export type connect_option = net::sockflag;

// Options for [[listen]].
export type listen_option = (backlog | net::sockflag);
