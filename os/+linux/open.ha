use fs;
use io;
use path;

// Opens a file from the filesystem.
//
// If no flags are provided, [fs::flags::RDONLY], [fs::flags::NOCTTY],
// [fs::flags::CLOEXEC] are used when opening the file. If you pass your own
// flags, it is recommended that you add the latter two unless you know that you
// do not want them.
export fn open(
	path: path::path,
	flags: fs::flags...
) (*io::stream | fs::error) = fs::open(cwd, path, flags...);

// Opens a file from the filesystem.
//
// If no flags are provided, [fs::flags::WRONLY], [fs::flags::NOCTTY],
// [fs::flags::CLOEXEC] are used when opening the file. If you pass your own
// flags, it is recommended that you add the latter two unless you know that you
// do not want them.
export fn create(
	path: path::path,
	mode: uint,
	flags: fs::flags...
) (*io::stream | fs::error) = fs::create(cwd, path, mode, flags...);
