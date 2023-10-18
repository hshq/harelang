// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use crypto::sha256;
use fs;
use hare::ast;
use hare::module;
use io;
use os::exec;
use path;
use strings;

export type error = !(exec::error | fs::error | io::error | module::error | path::error);

// a kind of cache file
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
	for (let i = 0z; i < len(t.rdeps); i += 1) {
		t.rdeps[i].ndeps -= 1;
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

export type context = struct {
	ctx: module::context,
	arch: str,
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
	// whether submodules of the root module should have tests enabled
	submods: bool,
	// if true, the main function won't be checked by harec
	freestanding: bool,

	cmds: [NSTAGES]str,

	mode: output,
	completed: size,
	total: size,

	mods: []module::module,
	hashes: [][NSTAGES]([sha256::SZ]u8 | void),
};

export fn ctx_finish(ctx: *context) void = {
	strings::freeall(ctx.ctx.tags);
	for (let i = 0z; i < len(ctx.defines); i += 1) {
		ast::ident_free(ctx.defines[i].ident);
		ast::type_finish(ctx.defines[i]._type);
		free(ctx.defines[i]._type);
		ast::expr_finish(ctx.defines[i].init);
		free(ctx.defines[i].init);
	};
	free(ctx.defines);
	free(ctx.libdirs);
	free(ctx.libs);
	ast::ident_free(ctx.ns);
	free(ctx.version);
	module::free_slice(ctx.mods);
	free(ctx.hashes);
};
