use errors;
use time;

export type localtime = struct {
	lapsed: (void | int),
	hour:   (void | int),
	min:    (void | int),
	sec:    (void | int),
	nsec:   (void | int),
};

fn init_time() localtime = localtime {
	lapsed = void,
	hour   = void,
	min    = void,
	sec    = void,
	nsec   = void,
};

// TODO: rework the following functions and their signatures

fn conv_time_localtime(t: time::duration) localtime = {
	const lt = localtime {
		lapsed = t: int,
		hour = (t / time::HOUR): int,
		min = ((t / time::MINUTE) % 60): int,
		sec = ((t / time::SECOND) % 60): int,
		nsec = (t % time::SECOND): int,
	};
	return lt;
};

fn conv_localtime_time(lt: localtime) (time::duration | errors::invalid) = {
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
