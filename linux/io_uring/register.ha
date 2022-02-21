// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use errors;
use rt;
use types;

// Registers a set of fixed buffers with an [[io_uring]]. Note that you must
// call [[unregister_buffers]] before registering a new set of buffers (even if
// some of them have similar addresses to the old set). The buffers must be
// anonymous, non-file-backed memory (e.g. the kind returned by alloc or
// rt::mmap).
export fn register_buffers(ring: *io_uring, iov: []rt::iovec) (void | error) = {
	assert(len(iov) <= types::UINT_MAX);
	match (rt::io_uring_register(ring.fd, regop::REGISTER_BUFFERS,
			iov: *[*]rt::iovec, len(iov): uint)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// Unregisters all fixed buffers associated with an [[io_uring]].
export fn unregister_buffers(ring: *io_uring) (void | error) = {
	match (rt::io_uring_register(ring.fd,
			regop::UNREGISTER_BUFFERS, null, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// Registers a set of file descriptors with an [[io_uring]]. The set of files
// may be sparse, meaning that some are set to -1, to be updated later using
// [[register_files_update]].
export fn register_files(ring: *io_uring, files: []int) (void | error) = {
	assert(len(files) <= types::UINT_MAX);
	match (rt::io_uring_register(ring.fd, regop::REGISTER_FILES,
			files: *[*]int, len(files): uint)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// Applies a set of [[files_update]]s to the set of files registered with an
// [[io_uring]].
export fn register_files_update(
	ring: *io_uring,
	updates: []files_update,
) (void | error) = {
	assert(len(updates) <= types::UINT_MAX);
	match (rt::io_uring_register(ring.fd, regop::REGISTER_FILES_UPDATE,
			updates: *[*]files_update, len(updates): uint)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// Unregisters all files associated with an [[io_uring]].
export fn unregister_files(ring: *io_uring) (void | error) = {
	match (rt::io_uring_register(ring.fd,
			regop::UNREGISTER_FILES, null, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// Registers an eventfd(2) with this [[io_uring]] to be notified of completion
// events.
export fn register_eventfd(ring: *io_uring, fd: int) (void | error) = {
	match (rt::io_uring_register(ring.fd,
			regop::REGISTER_EVENTFD, &fd, 1)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// Similar to [[register_eventfd]], but only notifies of events which complet
// asyncronously.
export fn register_eventfd_async(ring: *io_uring, fd: int) (void | error) = {
	match (rt::io_uring_register(ring.fd,
			regop::REGISTER_EVENTFD_ASYNC, &fd, 1)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// Unregisters the eventfd(2) associated with this [[io_uring]].
export fn unregister_eventfd(ring: *io_uring) (void | error) = {
	match (rt::io_uring_register(ring.fd,
			regop::UNREGISTER_EVENTFD, null, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// XXX: This interface is pretty bad. It would be nice to improve on it
// a bit before making it part of the API.
//export fn register_probe(ring: *io_uring, out: *probe, nops: size) void = {
//	assert(nops * size(probe_op) <= types::UINT_MAX);
//	match (rt::io_uring_register(ring.fd, regop::REGISTER_PROBE,
//			out, (nops * size(probe)): uint)) {
//		rt::errno => abort("Unexpected io_uring REGISTER_PROBE error"),
//		void => void,
//	};
//};

// Registers the current process's credentials as a personality with an
// [[io_uring]], returning an ID. Set the personality field of an [[sqe]] to use
// that personality for an I/O submission.
export fn register_personality(ring: *io_uring) int = {
	match (rt::io_uring_register(ring.fd,
			regop::REGISTER_PERSONALITY, null, 0)) {
	case rt::errno =>
		abort("Unexpected io_uring REGISTER_PERSONALITY error");
	case let i: int =>
		return i;
	};
};

// Unregisters a personality previously configured with
// [[register_personality]].
export fn unregister_personality(ring: *io_uring, id: int) (void | error) = {
	match (rt::io_uring_register(ring.fd,
			regop::UNREGISTER_PERSONALITY, null, id: uint)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// Enables submissions for an [[io_uring]] which was started in the disabled
// state via [[setup_flags::R_DISABLED]]. Future access to this io_uring is
// subject to any configured restrictions.
export fn register_enable_rings(ring: *io_uring) (void | error) = {
	match (rt::io_uring_register(ring.fd,
			regop::REGISTER_ENABLE_RINGS, null, 0)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};

// Registers a restriction for this [[io_uring]], limiting the kinds of future
// registrations and I/O submissions which are permitted for it. This is only
// accepted if the [[io_uring]] was set up in a disabled state via
// [[setup_flags::R_DISABLED]].
export fn register_restrictions(ring: *io_uring, res: []restriction) (void | error) = {
	assert(len(res) < types::UINT_MAX);
	match (rt::io_uring_register(ring.fd, regop::REGISTER_RESTRICTIONS,
			res: *[*]restriction, len(res): uint)) {
	case let err: rt::errno =>
		return errors::errno(err);
	case int => void;
	};
};
