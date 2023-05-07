use strings;

// Add a prefix to a buffer. The buffer will be modified, and it will
// remain normalized, so any ".." components in the original buffer may be
// collapsed.
export fn prepend(buf: *buffer, prefix: str...) (str | error) = {
	static let tmp = buffer { ... };
	tmp = *buf;
	set(buf, prefix...)?;
	return push(buf, string(&tmp));
};

@test fn prepend() void = {
	const buf = init("a")!;
	assert(prepend(&buf, "b")! == strings::fromutf8(['b', PATHSEP, 'a'])!);

	set(&buf, pathsepstr, "a")!;
	assert(prepend(&buf, "b")! == strings::fromutf8(['b', PATHSEP, 'a'])!);
};

