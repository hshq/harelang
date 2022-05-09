@test fn object() void = {
	let obj = newobject();
	defer finish(&obj);

	set(&obj, "hello", "world");
	set(&obj, "foo", "bar");
	set(&obj, "the answer", 42.0);

	assert(get(&obj, "hello") as str == "world");
	assert(get(&obj, "foo") as str == "foo");
	assert(get(&obj, "the answer") as str == 42.0);
	assert(get(&obj, "nonexistent") is void);

	del(&obj, "hello");
	assert(get(&obj, "hello") is void);
};
