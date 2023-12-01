// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use rt;

// Platform-specific path separator byte.
export def SEP: u8 = '/';

const sepstr: str = "/";

// Maximum length of a file path for this platform.
export def MAX: size = rt::PATH_MAX - 1;
