use hash::fnv;
use strings;

// TODO: Resize table as appropriate
def DEFAULT_OBJECT_BUCKETS: size = 32;

export type object = struct {
	buckets: [][](str, value),
};

// A JSON value.
export type value = (f64 | str | bool | _null | []value | object);

// Initializes a new (empty) JSON object. Call [[finish]] to free associated
// resources when you're done using it.
export fn newobject() object = {
	return object {
		buckets = alloc([[]...], DEFAULT_OBJECT_BUCKETS),
	};
};

// Gets a value from a JSON object. The return value is borrowed from the
// object.
export fn get(obj: *object, key: str) (*value | void) = {
	const hash = fnv::string64(key): size;
	const bucket = &obj.buckets[hash % len(obj.buckets)];
	for (let i = 0z; i < len(bucket); i += 1) {
		if (bucket[i].0 == key) {
			return &bucket[i].1;
		};
	};
};

// Sets a value in a JSON object. Assumes ownership over the provided value.
export fn set(obj: *object, key: str, val: const *value) void = {
	const val = dup(val);
	const hash = fnv::string64(key): size;
	const bucket = &obj.buckets[hash % len(obj.buckets)];
	for (let i = 0z; i < len(bucket); i += 1) {
		if (bucket[i].0 == key) {
			finish(&bucket[i].1);
			bucket[i].1 = val;
			return;
		};
	};
	append(bucket, (strings::dup(key), val));
};

// Deletes a value from a JSON object.
export fn del(obj: *object, key: str) void = {
	const hash = fnv::string64(key): size;
	const bucket = &obj.buckets[hash % len(obj.buckets)];
	for (let i = 0z; i < len(bucket); i += 1) {
		if (bucket[i].0 == key) {
			free(bucket[i].0);
			finish(&bucket[i].1);
			delete(bucket[i]);
			break;
		};
	};
};

// Duplicates a JSON value. The caller must pass the return value to [[finish]]
// to free associated resources when they're done using it.
export fn dup(val: *value) value = {
	// XXX: Match overhaul
	match (*val) {
	case let s: str =>
		return strings::dup(s);
	case let v: []value =>
		let new: []value = alloc([], len(v));
		for (let i = 0z; i < len(v); i += 1) {
			append(new, dup(&v[i]));
		};
		return new;
	case let o: object =>
		abort(); // TODO: Implement me after iter
	};
};

// Frees state associated with a JSON value.
export fn finish(val: *value) void = {
	// XXX: Match overhaul
	match (*val) {
	case let s: str =>
		free(s);
	case let v: []value =>
		for (let i = 0z; i < len(v); i += 1) {
			finish(&v[i]);
		};
		free(v);
	case let o: object =>
		for (let i = 0z; i < len(o.buckets); i += 1) {
			for (let j = 0z; j < len(o.buckets[i]); j += 1) {
				free(&o.buckets[i][j].0);
				finish(&o.buckets[i][j].1);
			};
			free(o.buckets[i]);
		};
	case => void;
	};
};
