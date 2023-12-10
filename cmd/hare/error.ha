// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use fs;
use hare::module;
use hare::parse;
use io;
use os::exec;
use path;
use strconv;
use cmd::hare::build;

type error = !(
	exec::error |
	fs::error |
	io::error |
	module::error |
	path::error |
	parse::error |
	strconv::error |
	unknown_arch |
	unknown_output |
	unknown_type |
	output_exists |
	output_failed |
	invalid_namespace |
	build::unknown_platform |
);

type unknown_arch = !str;

type unknown_output = !void;

type unknown_type = !str;

type output_exists = !str;

type output_failed = !(str, fs::error);

type invalid_namespace = !str;
