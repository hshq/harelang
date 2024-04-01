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
	if (!ctx.release) {
		module::gather(&ctx.ctx, &mods, ["debug"])?;
	};
	const nsubmods = if (ctx.submods) {
		let id: ast::ident = [];
		defer ast::ident_free(id);
		yield gather_submodules(&ctx.ctx, &mods, &buf, &id)?;
	} else 0z;

	ctx.top = match (module::gather(&ctx.ctx, &mods, &buf)) {
	case let top: size =>
		yield top;
	case let e: module::error =>
		if (!(unwrap_module_error(e) is module::not_found)
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

fn gather_submodules(
	ctx: *module::context,
	mods: *[]module::module,
	buf: *path::buffer,
	mod: *ast::ident,
) (size | error) = {
	let n = 0z;
	let it = os::iter(path::string(buf))?;
	defer fs::finish(it);

	for (let dir => module::next(it)?) {
		path::push(buf, dir.name)?;
		defer path::pop(buf);
		append(mod, dir.name);
		defer delete(mod[len(mod) - 1]);
		match (module::gather(ctx, mods, *mod)) {
		case size =>
			n += 1;
		case let e: module::error =>
			if (!(unwrap_module_error(e) is module::not_found)) {
				return e;
			};
		};
		n += gather_submodules(ctx, mods, buf, mod)?;
	};
	return n;
};
