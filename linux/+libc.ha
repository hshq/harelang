use rt;

@init fn ensure_rt_init() void = {
	rt::start_linux();
};
