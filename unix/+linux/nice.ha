// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use errors;
use rt;

// Adds the argument to the niceness of the current process. The input should be
// between -20 and 19 (inclusive); lower numbers represent a higher priority.
// Generally, you must have elevated permissions to reduce your niceness, but
// not to increase it.
export fn nice(inc: int) (void | errors::error) = {
	let prio = inc;
	if (inc > -40 && inc <= 40) {
		prio += rt::getpriority(rt::PRIO_PROCESS, 0) as int;
	};
	if (prio > 19) {
		prio = 19;
	};
	if (prio < -20) {
		prio = -20;
	};
	match (rt::setpriority(rt::PRIO_PROCESS, 0, prio)) {
	case void => void;
	case let err: rt::errno =>
		return errors::errno(err);
	};
};
