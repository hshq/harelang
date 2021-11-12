
//	// Represents a calendar system which supports datetimes
//	export type calendar = struct {
//	//	chrono::calendar,
//		to_localdate: *conv_daynum_localdate,
//		to_daynum: *conv_localdate_daynum,
//	};
//	
//	export type conv_daynum_localdate = fn(dn: daynum) localdate;
//	
//	export type conv_localdate_daynum = fn(ld: localdate) daynum;
//	
//	export type chronology = struct {
//	//	chrono::chronology,
//		to_datetime: *conv_moment_datetime,
//		to_moment: *conv_datetime_moment,
//	};
//	
//	export type conv_moment_datetime = fn(m: moment) datetime;
//	
//	export type conv_datetime_moment = fn(dt: datetime) moment;
