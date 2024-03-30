// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use crypto::sha256;
use fs;
use hare::ast;
use hare::module;
use io;
use os::exec;
use path;

export type error = !(exec::error | fs::error | io::error | module::error | path::error);

export type unknown_platform = !str;

export type stage = enum {
	TD = 0,
	SSA,
	S,
	O,
	BIN,
};

def NSTAGES = stage::BIN + 1;

// file extensions corresponding to each [[stage]]
export const stage_ext = ["td", "ssa", "s", "o", "bin"];

// a command in the queue to be run
export type task = struct {
	// number of unfinished dependencies
	ndeps: size,
	// tasks to update (by decrementing ndeps) when this task is finished
	rdeps: []*task,
	kind: stage,
	idx: size,
};

export fn free_task(t: *task) void = {
	for (let rdep &.. t.rdeps) {
		rdep.ndeps -= 1;
	};
	free(t.rdeps);
	free(t);
};

export type output = enum {
	DEFAULT,
	SILENT,
	VERBOSE,
	VVERBOSE,
};

export type arch = struct {
	name: str,
	qbe_name: str,
	as_cmd: str,
	cc_cmd: str,
	ld_cmd: str,
};

export type context = struct {
	ctx: module::context,
	arch: *arch,
	platform: *platform,
	goal: stage,
	defines: []ast::decl_const,
	libdirs: []str,
	libs: []str,
	jobs: size,
	ns: ast::ident,
	// index of the root module within the gathered module slice
	top: size,
	// output of harec -v
	version: []u8,
	// true if invoked as `hare test`
	test: bool,
	// true if building in release mode
	release: bool,
	// whether submodules of the root module should have tests enabled
	submods: bool,
	// if true, the main function won't be checked by harec
	freestanding: bool,
	// if true, we are linking with libc (using cc instead of ld)
	libc: bool,

	cmds: [NSTAGES]str,

	mode: output,
	completed: size,
	total: size,

	mods: []module::module,
	hashes: [][NSTAGES]([sha256::SZ]u8 | void),
};

export fn ctx_finish(ctx: *context) void = {
	free(ctx.ctx.tags);
	for (let define .. ctx.defines) {
		ast::ident_free(define.ident);
		ast::type_finish(define._type);
		free(define._type);
		ast::expr_finish(define.init);
		free(define.init);
	};
	free(ctx.defines);
	free(ctx.libdirs);
	free(ctx.libs);
	ast::ident_free(ctx.ns);
	free(ctx.version);
	module::free_slice(ctx.mods);
	free(ctx.hashes);
};
