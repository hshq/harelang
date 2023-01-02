export type epoll_event = struct {
	// Not packed on !x86_64
	events: u32,
	data: epoll_data,
};
