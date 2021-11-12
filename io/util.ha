// Reads an entire "item", i.e. one Hare object, from an I/O handle. This
// function may use multiple reads, but if [[EOF]] is encountered before the
// entire object is read, an [[underread]] error is returned. Otherwise, the
// return value is the total number of bytes read (which shall be equal to
// itemsz).
export fn readitem(in: handle, item: *void, itemsz: size) (size | error) = {
	let buf = item: *[*]u8;
	let i = 0z;
	for (i < itemsz) {
		match (io::read(in, buf[..(itemsz - i)])) {
		case io::EOF =>
			return underread;
		case z: size =>
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
