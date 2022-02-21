// License: MPL-2.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
use hare::types;

type context = struct {
	store: *types::typestore,
	scope: *scope,
	fntype: *types::func,
};
