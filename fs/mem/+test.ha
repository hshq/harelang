use bytes;
use errors;
use fs;
use io;
use strconv;

@test fn mem() void = {
	// TODO: Make type assertions with fs::error more specific once harec
	// permits that.
	const names: [6]str = ["foo", "bar", "baz", "quux", "hare.ha", "asdf"];
	let filename = names[0];

	let memfs = memopen();
	const input: [_]u8 = [0, 1, 2, 3, 4, 5];

	// fs::create, fs::stat
	for (let i = 0z; i < 6; i += 1) {
		let f = fs::create(memfs, names[i], 0, fs::flags::RDWR);
		let f = f as *io::stream;
		io::write(f, input[i..])!;
		io::close(f);
		let st = fs::stat(memfs,  names[i]) as fs::filestat;
		assert(st.mask & fs::stat_mask::SIZE == fs::stat_mask::SIZE);
		assert(st.sz == len(input) - i);
		assert(st.mode & fs::mode::REG == fs::mode::REG);
	};

	let f = fs::open(memfs, filename, fs::flags::WRONLY, fs::flags::APPEND);
	let f = f as *io::stream;
	io::write(f, input)!;
	io::close(f);
	let st = fs::stat(memfs,  filename) as fs::filestat;
	assert(st.sz == len(input) * 2);

	fs::create(memfs, filename, 0, fs::flags::RDONLY) as fs::error: void; // errors::exists

	// fs::open and read
	fs::open(memfs, "nonexistent", fs::flags::RDONLY) as fs::error: void; // errors::noentry
	let f = fs::open(memfs, filename, fs::flags::RDWR, fs::flags::EXCL);
	f as fs::error: void; // errors::unsupported
	fs::remove(memfs, "nonexistent") as fs::error: void; // errors::noentry

	let f = fs::open(memfs, filename, fs::flags::RDONLY) as *io::stream;
	let f2 = fs::open(memfs, filename, fs::flags::RDONLY) as *io::stream;
	let output: [12]u8 = [0...];
	assert(io::seek(f2, 3, io::whence::SET) as io::off == 3: io::off);
	assert(io::read(f2, output) as size == 9);
	io::close(f2);
	assert(io::read(f, output) as size == 12);
	assert(bytes::equal(input, output[..6]));
	assert(bytes::equal(input, output[6..]));
	io::close(f);

	// fs::iter
	let it = fs::iter(memfs, "") as *fs::iterator;
	defer free(it);
	let count = 0z;
	for (true) match (it.next(it)) {
		void => break,
		d: fs::dirent => count += 1,
	};
	assert(count == 6);

	// fs::mkdir
	fs::mkdir(memfs, "nonexistent/path") as fs::error: void; // errors::noentry
	fs::rmdir(memfs, "nonexistent/path") as fs::error: void; // errors::noentry
	fs::mkdir(memfs, "dir") as void;
	fs::open(memfs, "dir", fs::flags::RDONLY) as fs::error: void; // fs::wrongtype
	fs::mkdir(memfs, "dir") as fs::error: void; // errors::exists
	fs::mkdir(memfs, "dir/subdir") as void;
	fs::rmdir(memfs, "dir/subdir") as void;
	fs::rmdir(memfs, "dir") as void;
	fs::rmdir(memfs, "") as fs::error: void; // errors::invalid;

	fs::mkdir(memfs, "dir") as void;
	f = fs::create(memfs, "dir/file", 0, fs::flags::WRONLY) as *io::stream;
	assert(io::write(f, input[..]) as size == 6);
	io::close(f);
	f = fs::open(memfs, "dir/file", fs::flags::RDONLY) as *io::stream;
	assert(io::read(f, output) as size == 6);
	assert(bytes::equal(input, output[..6]));
	io::close(f);
	//fs::rmdir(memfs, "dir") as fs::error; // errors::busy
	fs::remove(memfs, "dir/file") as void;
	fs::rmdir(memfs, "dir") as void;

	// fs::mksubdir, fs::subdir
	fs::mksubdir(memfs, filename) as fs::error: void; // errors::exists
	fs::subdir(memfs, filename) as fs::error: void; // fs::wrongtype

	let sub = mksubdir(memfs, "dir") as *fs::fs;

	let f = fs::create(sub, "file", 0, fs::flags::WRONLY) as *io::stream;
	io::write(f, [42])!;
	io::close(f);

	let sub2 = fs::subdir(memfs, "dir") as *fs::fs;
	assert(sub2 == sub);
	fs::close(sub);

	let f = fs::open(sub2, "file", fs::flags::RDONLY) as *io::stream;
	assert(io::read(f, output) as size == 1);
	assert(output[0] == 42);
	io::close(f);

	// fs::close
	fs::close(memfs);

	// verify that subdirs can outlive parent dirs
	let memsub2 = sub2: *inode;
	fs::mkdir(sub2, "subdir") as void;
	fs::rmdir(sub2, "subdir") as void;
	assert(memsub2.opencount == 1);
	assert(memsub2.parent == null);
	fs::rmdirall(sub2, "")!;
	fs::close(sub2);
};

@test fn big_dir() void = {
	let limit = 32z;
	let memfs = memopen();
	for (let i = 0z; i < limit; i += 1) {
		let f = fs::create(memfs, strconv::ztos(i), 0, fs::flags::RDWR);
		io::close(f as *io::stream);
	};
	let ino = memfs: *inode;
	let dir = ino.data as directory;
	assert(dir.sz == limit);
	assert(len(dir.ents) > min_buckets);

	let it = fs::iter(memfs, "") as *fs::iterator;
	defer free(it);
	let count = 0z;
	for (true) match (it.next(it)) {
		void => break,
		d: fs::dirent => count += 1,
	};
	assert(count == limit);

	for (let i = 0z; i < limit; i += 1) {
		fs::remove(memfs, strconv::ztos(i))!;
	};
	let ino = memfs: *inode;
	let dir = ino.data as directory;
	assert(len(dir.ents) == min_buckets);
	assert(dir.sz == 0);
	fs::close(memfs);
};
