use errors;
use time;

// Represents a time of day as represented on a wall clock
export type localtime = struct {
	hour: (void | int),
	min: (void | int),
	sec: (void | int),
	nsec: (void | int),
};

export fn init_time() localtime = localtime {
	hour = void,
	min = void,
	sec = void,
	nsec = void,
};

// Converts a [[time::duration]] to a [[localtime]]
export fn conv_time_localtime(t: time::duration) localtime = {
	const lt = localtime {
		hour = (t / time::HOUR): int,
		min = ((t / time::MINUTE) % 60): int,
		sec = ((t / time::SECOND) % 60): int,
		nsec = (t % time::SECOND): int,
	};
	return lt;
};

// Converts a [[localtime]] to a [[time::duration]].
// Fails if any of the [[localtime]] fields are void.
export fn conv_localtime_time(lt: localtime) (time::duration | errors::invalid) = {
	if (
		lt.hour is void
		|| lt.min is void
		|| lt.sec is void
		|| lt.nsec is void
	) {
		return errors::invalid;
	};
	const t = (
		(lt.hour: int * time::HOUR) +
		(lt.min: int * time::MINUTE) +
		(lt.sec: int * time::SECOND) +
		(lt.nsec: int * time::NANOSECOND)
	);
	return t;
};
