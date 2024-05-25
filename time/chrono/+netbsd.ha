// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

def LOCALTIME_PATH: str = "/etc/localtime";
def TZDB_PATH: str = "/usr/share/zoneinfo/";

// The filepath of the system's "leap-seconds.list" file, which contains UTC/TAI
// leap second data.
export def UTC_LEAPSECS_PATH: str = "/usr/share/zoneinfo/leap-seconds.list";
