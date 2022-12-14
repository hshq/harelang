// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use net;
use io;
use rt;

// Adds a list of file descriptors to the ancillary data for a sendmsg
// operation.
export fn addfiles(buf: *net::msghdr, files: io::file...) void = {
	const msgsz = size(io::file) * len(files);
	let buf = net::addcontrol(buf, msgsz, rt::SOL_SOCKET, rt::SCM_RIGHTS);
	let buf = buf: *[*]io::file;
	buf[..len(files)] = files[..];
};

// Prepares an ancillary data buffer to receive files during a recvmsg
// operation.
export fn allocfiles(buf: *net::msghdr, nfile: size) void = {
	const msgsz = size(io::file) * nfile;
	net::addcontrol(buf, msgsz, rt::SOL_SOCKET, rt::SCM_RIGHTS);
};

// Receives files from an ancillary data buffer which was previously prepared
// with [[allocfiles]].
export fn recvfiles(buf: *net::msghdr, nfile: size) []io::file = {
	match (net::getcontrol(buf,
		nfile * size(io::file),
		rt::SOL_SOCKET, rt::SCM_RIGHTS)) {
	case let buf: []u8 =>
		return (buf: *[*]io::file)[..nfile];
	case void =>
		return [];
	};
};
