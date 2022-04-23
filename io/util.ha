// License: MPL-2.0
// (c) 2022 Bor Grošelj Simić <bor.groseljsimic@telemach.net>
// (c) 2021 Drew DeVault <sir@cmpwn.com>
// (c) 2021 Eyal Sawady <ecs@d2evs.net>

// Reads an entire "item", i.e. one Hare object, from an I/O handle. This
// function may use multiple reads, but if [[EOF]] is encountered before the
// entire object is read, an [[underread]] error is returned. Otherwise, the
// return value is the total number of bytes read (which shall be equal to
// itemsz).
export fn readitem(in: handle, item: *void, itemsz: size) (size | error) = {
	let buf = item: *[*]u8, i = 0z;
	for (i < itemsz) {
		match (read(in, buf[..(itemsz - i)])) {
		case EOF =>
			return i: underread: error;
		case let z: size =>
			i += z;
		};
	};
	return i;
};

// Reads several "items", i.e. Hare objects, from an I/O handle. If [[EOF]] is
// returned prior to reading all of the items completely, an [[underread]] error
// is returned. Otherwise, the return value is the number of items read.
export fn readitems(in: handle, items: []void, itemsz: size) (size | error) = {
	let buf = items: *[*]u8;
	readitem(in, buf, len(items) * itemsz)?;
	return len(items);
};

// Reads an entire buffer, perhaps issuing several [[read]] calls to do so. If
// EOF is immediately encountered, it is returned; if [[EOF]] is encountered
// partway through reading the buffer, [[underread]] is returned.
export fn readall(in: handle, buf: []u8) (size | EOF | error) = {
	let z: size = 0;
	for (z < len(buf)) {
		match (read(in, buf[z..])?) {
		case EOF =>
			if (z == 0) {
				return EOF;
			};
			return z: underread: error;
		case let n: size =>
			z += n;
		};
	};
	return z;
};

// Writes an entire "item", i.e. one Hare object, to an I/O handle. This
// function may use multiple writes. The return value is the total number of
// bytes written (which shall be equal to itemsz).
export fn writeitem(
	out: handle,
	item: *const void,
	itemsz: size,
) (size | error) = {
	const buf = item: *[*]u8;
	let i = 0z;
	for (i < itemsz) {
		i += write(out, buf[i..(itemsz - i)])?;
	};
	return i;
};

// Writes several "items", i.e. Hare objects, to an I/O handle. If successful,
// all items will be written. The return value is the number of items written.
export fn writeitems(
	out: handle,
	items: []const void,
	itemsz: size,
) (size | error) = {
	const buf = items: *[*]u8;
	writeitem(out, buf, len(items) * itemsz)?;
	return len(items);
};

// Writes an entire buffer, perhaps issuing several [[write]] calls to do so.
export fn writeall(out: handle, buf: []u8) (size | error) = {
	let z: size = 0;
	for (z < len(buf)) {
		z += write(out, buf[z..])?;
	};
	return z;
};
