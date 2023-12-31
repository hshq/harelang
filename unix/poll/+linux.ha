// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use io;
use rt;
use time;

// Events bitfield for the events and revents field of [[pollfd]].
export type event = enum i16 {
	POLLIN = 1,
	POLLPRI = 2,
	POLLOUT = 4,
	POLLERR = 8,
	POLLHUP = 16,
};

// A single file descriptor to be polled.
export type pollfd = struct {
	fd: io::file,
	events: i16,
	revents: i16,
};

// Pass this [[time::duration]] to [[poll]] to cause it wait indefinitely for
// the next event.
export def INDEF: time::duration = -1;

// Pass this [[time::duration]] to [[poll]] to cause it to return immediately if
// no events are available.
export def NONBLOCK: time::duration = 0;

// Polls for the desired events on a slice of [[pollfd]]s, blocking until an
// event is available, or the timeout expires. Set the timeout to [[INDEF]] to
// block forever, or [[NONBLOCK]] to return immediately if no events are
// available. Returns the number of [[pollfd]] items which have events, i.e.
// those which have revents set to a nonzero value.
export fn poll(
	fds: []pollfd,
	timeout: time::duration,
) (uint | error) = {
	let ts = time::duration_to_timespec(timeout);
	let ts = if (timeout == INDEF) null else &ts;
	match (rt::ppoll(fds: *[*]pollfd: *[*]rt::pollfd, len(fds), ts, null)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case let n: int =>
		return n: uint;
	};
};
