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
		min = ((t / time::MINUTE) % 60): int,
		sec = ((t / time::SECOND) % 60): int,
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


