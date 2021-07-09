use errors;
use fs;
use rt;

// Sets the file mode creation mask for the current process and return the
// previous value of the mask. Only the file permission bits are used.
export fn umask(mode: fs::mode) (fs::mode | errors::error) = {
	mode &= 0o777;
	return match (rt::umask(mode)) {
		mode: rt::mode_t => mode: fs::mode,
		err: rt::errno => errors::errno(err),
	};
};
