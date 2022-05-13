// License: MPL-2.0
// (c) 2022 Drew DeVault <sir@cmpwn.com>
use hash::fnv;
use strings;

// TODO: Resize table as appropriate
def OBJECT_BUCKETS: size = 32;

export type object = struct {
	buckets: [OBJECT_BUCKETS][](str, value),
};

// A JSON value.
export type value = (f64 | str | bool | _null | []value | object);

// Initializes a new (empty) JSON object. Call [[finish]] to free associated
// resources when you're done using it.
export fn newobject() object = {
	return object { ... };
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

// Sets a value in a JSON object.
export fn set(obj: *object, key: const str, val: const value) void = {
	const hash = fnv::string64(key): size;
	const bucket = &obj.buckets[hash % len(obj.buckets)];
	for (let i = 0z; i < len(bucket); i += 1) {
		if (bucket[i].0 == key) {
			finish(bucket[i].1);
			bucket[i].1 = dup(val);
			return;
		};
	};
	append(bucket, (strings::dup(key), dup(val)));
};

// Deletes a value from a JSON object.
export fn del(obj: *object, key: const str) void = {
	const hash = fnv::string64(key): size;
	const bucket = &obj.buckets[hash % len(obj.buckets)];
	for (let i = 0z; i < len(bucket); i += 1) {
		if (bucket[i].0 == key) {
			free(bucket[i].0);
			finish(bucket[i].1);
			delete(bucket[i]);
			break;
		};
	};
};

export type iterator = struct {
	obj: *object,
	i: size,
	j: size,
};

// Creates an iterator that enumerates over the key/value pairs in an
// [[object]].
export fn iter(obj: *object) iterator = {
	return iterator { obj = obj, ... };
};

// Returns the next key/value pair from this iterator, or void if none remain.
export fn next(iter: *iterator) ((const str, const *value) | void) = {
	for (iter.i < len(iter.obj.buckets); iter.i += 1) {
		const bucket = &iter.obj.buckets[iter.i];
		for (iter.j < len(bucket)) {
			const key = bucket[iter.j].0;
			const val = &bucket[iter.j].1;
			iter.j += 1;
			return (key, val);
		};
		iter.j = 0;
	};
};

// Duplicates a JSON value. The caller must pass the return value to [[finish]]
// to free associated resources when they're done using it.
export fn dup(val: value) value = {
	match (val) {
	case let s: str =>
		return strings::dup(s);
	case let v: []value =>
		let new: []value = alloc([], len(v));
		for (let i = 0z; i < len(v); i += 1) {
			append(new, dup(v[i]));
		};
		return new;
	case let o: object =>
		let new = newobject();
		const i = iter(&o);
		for (true) {
			const pair = match (next(&i)) {
			case void =>
				break;
			case let pair: (const str, const *value) =>
				yield pair;
			};
			set(&new, pair.0, *pair.1);
		};
		return new;
	case =>
		return val;
	};
};

// Frees state associated with a JSON value.
export fn finish(val: value) void = {
	match (val) {
	case let s: str =>
		free(s);
	case let v: []value =>
		for (let i = 0z; i < len(v); i += 1) {
			finish(v[i]);
		};
		free(v);
	case let o: object =>
		for (let i = 0z; i < len(o.buckets); i += 1) {
			const bucket = &o.buckets[i];
			for (let j = 0z; j < len(bucket); j += 1) {
				free(bucket[j].0);
				finish(bucket[j].1);
			};
			// TODO: https://todo.sr.ht/~sircmpwn/hare/690
			//free(bucket);
		};
	case => void;
	};
};
