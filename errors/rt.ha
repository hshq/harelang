// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Wraps an [[rt::errno]] to produce an [[error]], which may be [[opaque_]].
// This is a non-portable interface which is mainly provided to support internal
// stdlib requirements.
export fn errno(errno: rt::errno) error = {
	switch (errno) {
	case rt::ECONNREFUSED =>
		return refused;
	case rt::ECANCELED =>
		return cancelled;
	case rt::EOVERFLOW =>
		return overflow;
	case rt::EACCES =>
		return noaccess;
	case rt::EINVAL =>
		return invalid;
	case rt::EEXIST =>
		return exists;
	case rt::ENOENT =>
		return noentry;
	case rt::ETIMEDOUT =>
		return timeout;
	case rt::EBUSY =>
		return busy;
	case rt::EINTR =>
		return interrupted;
	case rt::EAGAIN =>
		return again;
	case => void;
	};

	static assert(size(rt::errno) <= size(opaque_data));
	let err = opaque_ { strerror = &rt_strerror, ... };
	let ptr = &err.data: *rt::errno;
	*ptr = errno;
	return err;
};

fn rt_strerror(err: *opaque_data) const str = {
	let err = err: *rt::errno;
	return rt::strerror(*err);
};
