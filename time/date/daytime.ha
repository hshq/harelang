// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use time;

// Calculates the wall clock (hour, minute, second, nanosecond),
// given a time-of-day (amount of daytime progressed in a day).
fn calc_hmsn(t: i64) (int, int, int, int) = {
	// TODO: Special case for leap seconds, 61st second?
	const hour = (t / time::HOUR): int;
	const min = ((t / time::MINUTE) % 60): int;
	const sec = ((t / time::SECOND) % 60): int;
	const nsec = (t % time::SECOND): int;
	return (hour, min, sec, nsec);
};

// Calculates the time-of-day (amount of daytime progressed in a day),
// given a wall clock (hour, minute, second, nanosecond).
fn calc_daytime__hmsn(
	hour: int,
	min: int,
	sec: int,
	nsec: int,
) (i64 | invalid) = {
	const t = (
		(hour * time::HOUR) +
		(min * time::MINUTE) +
		(sec * time::SECOND) +
		(nsec * time::NANOSECOND)
	);
	return t;
};
