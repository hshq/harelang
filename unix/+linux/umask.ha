use errors;
use fs;
use rt;

// Sets the file mode creation mask for the current process and return the
// previous value of the mask.
export fn umask(mode: fs::mode) (fs::mode | errors::error) = {
	match (rt::umask(mode)) {
	case mode: rt::mode_t =>
		return mode: fs::mode;
	case err: rt::errno =>
		return errors::errno(err);
	};
};
