// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fs;
use hare::ast;
use hare::module;
use os;
use path;
use strings;

export fn gather(ctx: *context, input: str) ([]module::module | error) = {
	let mods: []module::module = [];
	path::set(&buf, input)!;
	module::gather(&ctx.ctx, &mods, ["rt"])?;
	if (ctx.test) {
		module::gather(&ctx.ctx, &mods, ["test"])?;
	};
	if (!ctx.release && ctx.platform.debug_supported) {
		module::gather(&ctx.ctx, &mods, ["debug"])?;
	};
	const nsubmods = if (ctx.submods) {
		let id: ast::ident = [];
		defer ast::ident_free(id);
		yield module::gather_submodules(&ctx.ctx, &mods, &buf, &id)?;
	} else 0z;

	ctx.top = match (module::gather(&ctx.ctx, &mods, &buf)) {
	case let top: size =>
		yield top;
	case let e: module::error =>
		if (!(module::unwrap_error(e) is module::not_found)
				|| nsubmods == 0) {
			return e;
		};
		// running `hare test` with no args in a directory which isn't a
		// module
		// add a dummy module so the driver knows where in the cache to
		// put the test runner binary
		append(mods, module::module {
			path = strings::dup(input),
			...
		});
		yield len(mods) - 1;
	};
	return mods;
};
