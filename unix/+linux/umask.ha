use errors;
use fs;
use rt;

// Sets the file mode creation mask for the current process and return the
// previous value of the mask.
export fn umask(mode: fs::mode) (fs::mode | errors::error) = {
	return match (rt::umask(mode)) {
		mode: rt::mode_t => mode: fs::mode,
		err: rt::errno => errors::errno(err),
	};
};
