// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

// Values that may be passed to [[exit]] to indicate successful or unsuccessful
// termination, respectively.
export type status = enum {
	SUCCESS = 0,
	FAILURE = 1,
};
