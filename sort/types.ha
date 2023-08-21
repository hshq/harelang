// License: MPL-2.0
// (c) 2022 Sebastian <sebastian@sebsite.pw>
use strings;

// This function type is used when sorting and searching. Given two pointers to
// values, a function of this type should return an integer less than, equal to,
// or greater than zero if the first argument is, respectively, less than, equal
// to, or greater than the second argument.
export type cmpfunc = fn(a: const *opaque, b: const *opaque) int;

fn scmp(a: const *opaque, b: const *opaque) int = {
	const a = a: const *str, b = b: const *str;
	return strings::compare(*a, *b);
};

fn icmp(a: const *opaque, b: const *opaque) int = {
	const a = *(a: const *int), b = *(b: const *int);
	return if (a < b) -1
		else if (a > b) 1
		else 0;
};
