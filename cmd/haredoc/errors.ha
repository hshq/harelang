// License: GPL-3.0
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Ember Sawady <ecs@d2evs.net>
use hare::lex;
use hare::module;
use hare::parse;
use io;

type error = !(lex::error | parse::error | io::error | module::error);

fn strerror(err: error) str = {
	match (err) {
	case let err: lex::error =>
		return lex::strerror(err);
	case let err: parse::error =>
		return parse::strerror(err);
	case let err: io::error =>
		return io::strerror(err);
	case let err: module::error =>
		return module::strerror(err);
	};
};
