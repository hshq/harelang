// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use hare::types;

type context = struct {
	store: *types::typestore,
	scope: *scope,
	fntype: nullable *types::func,
};
