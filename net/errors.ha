// License: MPL-2.0
// (c) 2021 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>
use errors;
use io;

// An attempt was made to use an unsupported protocol.
export type unknownproto = !void;

// All error types which can be returned from networking functions.
export type error = !(unknownproto | ...errors::error);

// Converts an [[error]] into a human-readable string.
export fn strerror(err: error) const str = {
	match (err) {
	case unknownproto =>
		return "Unsupported protocol";
	case let err: errors::error =>
		return errors::strerror(err);
	};
};
