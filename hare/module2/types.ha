use crypto::sha256;
use hare::ast;
use time;

// The module type stores information about a Hare module, including a list of
// files used as inputs to the build, information about other modules it depends
// on, and its ABI hash and cache key.
// 
// Note that for modules loaded from disk (rather than from the cache), the
// cache key will be initialized to zero, and the ABI keys for each of the
// dependencies will also be initialized to zero. The user must finish resolving
// the dependency graph in order to determine the appropriate configuration to
// store into the cache for this module.
export type module = struct {
	cachekey: [sha256::SIZE]u8,
	base: str,
	ident: ast::ident,
	abi: [sha256::SIZE]u8,
	depends: []dependency,
	inputs: []file,
	dirs: []directory,
};

// The type of an input file, either a Hare source file or an assembly source
// file.
export type filetype = enum {
	ASM,
	HARE,
};

// A file used as input to a Hare module.
export type file = struct {
	path: str,
	ftype: filetype,
	hash: [sha256::SIZE]u8,
	mtime: time::instant,
};

// A directory which stores some of the input files for a Hare module.
export type directory = struct {
	path: str,
	mtime: time::instant,
};

// A dependency of a Hare module. Note that if the required ABI hash is unknown,
// it will be initialized to zero and should be presumed to require the latest
// ABI version.
export type dependency = struct {
	ident: ast::ident,
	abi: [sha256::SIZE]u8,
};
