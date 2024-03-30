// SPDX-License-Identifier: MPL-2.0
// (c) Hare authors <https://harelang.org>

use ascii;
use errors;
use strings;

const tspecial: str = "()<>@,;:\\/[]?=";
export type type_params = strings::tokenizer;

// Parses a Media Type, returning a tuple of the content type (e.g.
// "text/plain") and a parameter parser object, or [[errors::invalid]] if the
// input cannot be parsed.
//
// To enumerate the Media Type parameter list, pass the type_params object into
// [[next_param]]. If you do not need the parameter list, you can safely discard
// the object. Note that any format errors following the ";" token will not
// cause [[errors::invalid]] to be returned unless [[next_param]] is used to
// enumerate all of the parameters.
export fn parse(in: str) ((str, type_params) | errors::invalid) = {
	const items = strings::cut(in, ";");
	const mtype = items.0, params = items.1;
	const items = strings::cut(mtype, "/");
	if (len(items.0) < 1 || len(items.1) < 1) {
		return errors::invalid;
	};
	typevalid(items.0)?;
	typevalid(items.1)?;
	return (mtype, strings::tokenize(params, ";"));
};

// Returns the next parameter as a (key, value) tuple from a [[type_params]]
// object that was prepared via [[parse]], void if there are no remaining
// parameters, and [[errors::invalid]] if a syntax error was encountered.
export fn next_param(in: *type_params) ((str, str) | void | errors::invalid) = {
	const tok = match (strings::next_token(in: *strings::tokenizer)) {
	case let s: str =>
		if (s == "") {
			// empty parameter
			return errors::invalid;
		};
		yield s;
	case done =>
		return;
	};

	const items = strings::cut(tok, "=");
	// The RFC does not permit whitespace here, but whitespace is very
	// common in the wild. ¯\_(ツ)_/¯
	items.0 = strings::trim(items.0);
	items.1 = strings::trim(items.1);
	if (len(items.0) == 0 || len(items.1) == 0) {
		return errors::invalid;
	};

	if (strings::hasprefix(items.1, "\"")) {
		items.1 = quoted(items.1)?;
	};

	return (items.0, items.1);
};

fn quoted(in: str) (str | errors::invalid) = {
	// We have only a basic implementation of quoted-string. It has a couple
	// of problems:
	//
	// 1. The RFC does not define it very well
	// 2. The parts of the RFC which are ill-defined are rarely used
	// 3. Implementing quoted-pair would require allocating a new string
	//
	// This implementation should handle most Media Types seen in practice
	// unless they're doing something weird and ill-advised with them.
	in = strings::trim(in, '"');
	if (strings::contains(in, "\\")
			|| strings::contains(in, "\r")
			|| strings::contains(in, "\n")) {
		return errors::invalid;
	};
	return in;
};

fn typevalid(in: str) (void | errors::invalid) = {
	const miter = strings::iter(in);
	for (let rn => strings::next(&miter)) {
		if (!ascii::valid(rn) || rn == ' '
				|| ascii::iscntrl(rn)
				|| strings::contains(tspecial, rn)) {
			return errors::invalid;
		};
	};
};

@test fn parse() void = {
	const res = parse("text/plain")!;
	assert(res.0 == "text/plain");

	const res = parse("image/png")!;
	assert(res.0 == "image/png");

	const res = parse("application/svg+xml; charset=utf-8; foo=\"bar baz\"")!;
	assert(res.0 == "application/svg+xml");
	const params = res.1;
	const param = next_param(&params)! as (str, str);
	assert(param.0 == "charset" && param.1 == "utf-8");
	const param = next_param(&params)! as (str, str);
	assert(param.0 == "foo" && param.1 == "bar baz");
	assert(next_param(&params) is void);

	assert(parse("hi") is errors::invalid);
	assert(parse("text/ spaces ") is errors::invalid);
	assert(parse("text/@") is errors::invalid);

	const res = parse("text/plain;charset")!;
	assert(res.0 == "text/plain");
	assert(next_param(&res.1) is errors::invalid);
};
