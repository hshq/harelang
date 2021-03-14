// The elapsed time between two instants, in nanoseconds. The largest
// representable duration is about 290 years.
export type duration = i64;

export def NANOSECOND: duration		= 1;
export def MICROSECOND: duration	= 1000 * NANOSECOND;
export def MILLISECOND: duration	= 1000 * MICROSECOND;
export def SECOND: duration		= 1000 * MILLISECOND;
export def MINUTE: duration		= 60 * SECOND;
export def HOUR: duration		= 60 * MINUTE;
