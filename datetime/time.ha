use errors;
use time;

fn calc_hmsn(t: time::duration) (int, int, int, int) = {
	const hour = (t / time::HOUR): int;
	const min = ((t / time::MINUTE) % 60): int;
	const sec = ((t / time::SECOND) % 60): int;
	const nsec = (t % time::SECOND): int;
	return (hour, min, sec, nsec);
};

fn calc_time_from_hmsn(
	hour: int,
	min: int,
	sec: int,
	nsec: int,
) (time::duration | errors::invalid) = {
	const t = (
		(hour * time::HOUR) +
		(min * time::MINUTE) +
		(sec * time::SECOND) +
		(nsec * time::NANOSECOND)
	);
	return t;
};
