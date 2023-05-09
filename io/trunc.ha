// License: MPL-2.0

// Truncate a file to a specified length. The file must be open for writing.
export fn trunc(fd: file, ln: size) (void | error) = platform_trunc(fd, ln);
