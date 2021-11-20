use errors;
use fmt;
use time::chrono;

@test fn strptime() void = {
	let dt = datetime {...};

	// General tests
	strptime("%Y-%m-%d %H:%M:%S.%N", "1994-08-27 11:01:02.123", &dt)!;
	assert(dt.date.year as int == 1994 &&
		dt.date.month as int == 08 &&
		dt.date.day as int == 27 &&
		dt.time.hour as int == 11 &&
		dt.time.min as int == 01 &&
		dt.time.sec as int == 02 &&
		dt.time.nsec as int == 123, "invalid parsing results");

	strptime("%k:%M:%S.%N%n%t%%", " 9:01:02.123\n\t%", &dt)!;
	assert(dt.time.hour as int == 9 &&
		dt.time.min as int == 01 &&
		dt.time.sec as int == 02 &&
		dt.time.nsec as int == 123, "invalid parsing results");

	strptime("%G-%m-%e", "994-8- 9", &dt)!;
	assert(dt.date.isoweekyear as int == 994 &&
		dt.date.month as int == 8 &&
		dt.date.day as int == 9, "invalid parsing results");

	// General errors
	assert(strptime("%Y-%m-%d", "1a94-08-27", &dt) is errors::invalid,
		"invalid datetime string did not throw error");

	assert(strptime("%Y-%m-%d", "1994-123-27", &dt) is errors::invalid,
		"invalid datetime string did not throw error");

	assert(strptime("%Y-%m-%d", "a994-08-27", &dt) is errors::invalid,
		"invalid datetime string did not throw error");

	// Basic specifiers
	strptime("%a", "Tue", &dt)!;
	assert(dt.date.weekday as int == 2, "invalid parsing results");

	strptime("%a %d", "Tue 27", &dt)!;
	assert(dt.date.weekday as int == 2 &&
		dt.date.day as int == 27, "invalid parsing results");

	strptime("%A", "Tuesday", &dt)!;
	assert(dt.date.weekday as int == 2, "invalid parsing results");

	strptime("%b", "Feb", &dt)!;
	assert(dt.date.month as int == 2, "invalid parsing results");

	strptime("%h", "Feb", &dt)!;
	assert(dt.date.month as int == 2, "invalid parsing results");

	strptime("%B", "February", &dt)!;
	assert(dt.date.month as int == 2, "invalid parsing results");

	strptime("%I", "14", &dt)!;
	assert(dt.time.hour as int == 2, "invalid parsing results");

	strptime("%j", "123", &dt)!;
	assert(dt.date.yearday as int == 123, "invalid parsing results");

	strptime("%l", " 9", &dt)!;
	assert(dt.time.hour as int == 9, "invalid parsing results");

	strptime("%H %p", "6 AM", &dt)!;
	assert(dt.time.hour as int == 6, "invalid parsing results");

	strptime("%H %p", "6 PM", &dt)!;
	assert(dt.time.hour as int == 18, "invalid parsing results");

	assert(strptime("%H %p", "13 PM", &dt) is errors::invalid,
		"invalid parsing results");

	assert(strptime("%H %p", "PM 6", &dt) is errors::invalid,
		"invalid parsing results");

	strptime("%H %P", "6 am", &dt)!;
	assert(dt.time.hour as int == 6, "invalid parsing results");

	strptime("%u", "7", &dt)!;
	assert(dt.date.weekday as int == 7, "invalid parsing results");

	strptime("%U", "2", &dt)!;
	assert(dt.date.week as int == 2, "invalid parsing results");

	strptime("%U", "99", &dt)!;
	assert(dt.date.week as int == 53, "invalid parsing results");

	strptime("%V", "12", &dt)!;
	assert(dt.date.isoweek as int == 12, "invalid parsing results");

	strptime("%w", "0", &dt)!;
	assert(dt.date.weekday as int == 7, "invalid parsing results");

	strptime("%W", "2", &dt)!;
	assert(dt.date.week as int == 2, "invalid parsing results");

	// Expansion specifiers
	strptime("%c", "Tue Feb  2 22:12:50 1994", &dt)!;
	assert(dt.date.day as int == 2 &&
		dt.date.month as int == 2 &&
		dt.date.year as int == 1994 &&
		dt.date.weekday as int == 2 &&
		dt.time.hour as int == 22 &&
		dt.time.min as int == 12 &&
		dt.time.sec as int == 50, "invalid parsing results");

	strptime("%D", "08/2/1994", &dt)!;
	assert(dt.date.day as int == 2 &&
		dt.date.month as int == 8 &&
		dt.date.year as int == 1994, "invalid parsing results");

	strptime("%F", "1994-08-27", &dt)!;
	assert(dt.date.day as int == 27 &&
		dt.date.month as int == 08 &&
		dt.date.year as int == 1994, "invalid parsing results");

	strptime("%r", "04:20:12 PM", &dt)!;
	assert(dt.time.hour as int == 16 &&
		dt.time.min as int == 20 &&
		dt.time.sec as int == 12, "invalid parsing results");

	strptime("%r", "04:20:12 AM", &dt)!;
	assert(dt.time.hour as int == 04 &&
		dt.time.min as int == 20 &&
		dt.time.sec as int == 12, "invalid parsing results");

	strptime("%R", "12:2", &dt)!;
	assert(dt.time.hour as int == 12 &&
		dt.time.min as int == 2, "invalid parsing results");

	strptime("%T", "12:2:12", &dt)!;
	assert(dt.time.hour as int == 12 &&
		dt.time.min as int == 2 &&
		dt.time.sec as int == 12, "invalid parsing results");
};
