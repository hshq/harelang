use time;

// Represents a ISO time of day
export type localtime = struct {
	hour: int,
	min: int,
	sec: int,
	nsec: int,
};

export fn conv_time_localtime(t: time::duration) localtime = {
	const lt = localtime {
		hour = (t / time::HOUR): int,
		min = (t / time::MINUTE): int % 60,
		sec = (t / time::SECOND): int % 60,
		nsec = (t % time::SECOND): int,
	};
	return lt;
};

export fn conv_localtime_time(lt: localtime) time::duration = {
	const t = (
		(lt.hour * time::HOUR) +
		(lt.min * time::MINUTE) +
		(lt.sec * time::SECOND) +
		(lt.nsec * time::NANOSECOND)
	);
	return t;
};


