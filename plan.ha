use hare::module;

type status = enum {
	SCHEDULED,
	COMPLETE,
};

type task = struct {
	status: status,
	inputs: []module::input,
	depend: []*task,
	output: str,
	cmd: []str,
};

type plan = struct {
	scheduled: []*task,
	complete: []*task,
};
