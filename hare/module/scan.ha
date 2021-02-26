use fs;
use hare::ast;
use slice;
use path;
use io;

// Scans the files in a directory for eligible build inputs and returns a
// [version] which includes all applicable files.
export fn scan(ctx: *context, path: path::path) (version | error) = {
	abort();
};

// Looks up a module by its identifier from HAREPATH, and returns a [version]
// which includes all eligible build inputs.
export fn lookup(ctx: *context, name: ast::ident) (version | error) = {
	abort();
};
