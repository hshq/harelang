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
			return underread;
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

// Writes an entire "item", i.e. one Hare object, to an I/O handle. This
// function may use multiple writes. The return value is the total number of
// bytes written (which shall be equal to itemsz).
export fn writeitem(out: handle, item: *void, itemsz: size) (size | error) = {
	let buf = item: *[*]u8, i = 0z;
	for (i < itemsz) {
		i += write(out, buf[i..(itemsz - i)])?;
	};
	return i;
};

// Writes several "items", i.e. Hare objects, to an I/O handle. The return value
// is the number of items written.
export fn writeitems(in: handle, items: []void, itemsz: size) (size | error) = {
	let buf = items: *[*]u8;
	writeitem(in, buf, len(items) * itemsz)?;
	return len(items);
};
