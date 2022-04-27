use fmt;
use io;
use math;
use unix::tty;

fn progress_update(plan: *plan) void = {
	const tty = match (plan.progress.tty) {
	case let f: io::file =>
		yield f;
	case =>
		return;
	};

	const width = match (tty::winsize(tty)) {
	case let ts: tty::ttysize =>
		yield if (ts.columns > 64) 64 else ts.columns;
	case =>
		yield 64;
	}: size;

	const complete = plan.progress.complete,
		total = plan.progress.total,
		current_module = plan.progress.current_module;

	const total_width = math::ceilf64(math::log10f64(total: f64)): size;
	const counter_width = 1 + total_width + 1 + total_width + 3;
	const progress_width = width - counter_width - 2 - len(current_module);

	fmt::fprintf(tty, "\r\x1b[K[{%}/{}] [",
		complete, &fmt::modifiers {
			width = total_width: uint,
			...
		},
		total)!;
	const stop = (complete: f64 / total: f64 * progress_width: f64): size;
	for (let i = 0z; i < progress_width; i += 1) {
		if (i > stop) {
			fmt::fprint(tty, ".")!;
		} else {
			fmt::fprint(tty, "#")!;
		};
	};
	if (len(current_module) > 0) {
		fmt::fprintf(tty, "] {}", current_module)!;
	} else {
		// Don't print a leading space
		fmt::fprint(tty, "]")!;
	};
};

fn progress_clear(plan: *plan) void = {
	const tty = match (plan.progress.tty) {
	case let f: io::file =>
		yield f;
	case =>
		return;
	};
	fmt::fprint(tty, "\r\x1b[K")!;
};

fn progress_increment(plan: *plan) void = {
	plan.progress.complete += 1;
	progress_update(plan);
};
