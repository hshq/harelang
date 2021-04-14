use errors;
use fs;
use hash::fnv;
use hash;
use path;
use strings;

def min_buckets: size = 1 << 3;
def max_buckets: size = 1 << 24;

fn ensure(parent: *inode) void = {
	let dir = parent.data: directory;
	let old = dir.ents;
	let new_size = 0z;
	if (dir.sz: u64 * 3u64 >= len(dir.ents): u64 * 4u64) {
		new_size = len(dir.ents) << 1;
		if (new_size > max_buckets) {
			new_size = max_buckets;
		};
	} else if (dir.sz: u64 * 10u64 < len(dir.ents): u64) {
		new_size = len(dir.ents) >> 3;
		if (new_size < min_buckets) {
			new_size = min_buckets;
		};
	} else {
		return;
	};
	dir.ents = alloc([], new_size);
	for (let i = 0z; i < new_size; i += 1) {
		append(dir.ents, null);
	};
	parent.data = dir;
	for (let i = 0z; i < len(old); i += 1) {
		for (true) match (old[i]) {
			null => break,
			ino: *inode => {
				old[i] = ino.next;
				_inode_insert(parent, ino);
			},
		};
	};
};

fn inode_insert(parent: *inode, ino: *inode) void = {
	ensure(parent);
	_inode_insert(parent, ino);
	let p = parent.data as directory;
	p.sz += 1;
	parent.data = p;
};

fn _inode_insert(parent: *inode, ino: *inode) void = {
	let p = parent.data as directory;
	let idx: size = ino.hash % len(p.ents): u64;
	ino.next = p.ents[idx];
	p.ents[idx] = ino;
	parent.data = p;
};

fn unlink(parent: *inode, ino: *inode) void = {
	let p = parent.data as directory;
	let prev = &p.ents[ino.hash % len(p.ents): u64];
	let it = *prev;
	for (true) match (it) {
		null => break,
		ii: *inode => {
			if (ii.hash == ino.hash && ii.name == ino.name) {
				*prev = ii.next;
				break;
			};
			prev = &ii.next;
			it = ii.next;
		},
	};
	p.sz -= 1;
	parent.data = p;
	ensure(parent);
};

fn inode_free(ino: *inode) void = {
	match (ino.data) {
		d: directory => free(d.ents),
		f: file      => free(f),
	};
	free(ino.name);
	free(ino);
};

fn inode_find(dir: *inode, path: str) (*inode | fs::error) = {
	if (path == "") {
		return dir;
	};
	let it = path::iter(path);
	return find_rec(dir, path::next(&it) as str, &it);
};

fn find_rec(dir: *inode, name: str, it: *path::iterator) (*inode | fs::error) = {
	let p = dir.data as directory;
	let bucket = p.ents[hash_of(name) % len(p.ents): u64];
	for (true) match (bucket) {
		null => break,
		ino: *inode => {
			if (name == ino.name) {
				return match (path::next(it)) {
					void => ino,
					name: str => find_rec(ino, name, it),
				};
			};
			bucket = ino.next;
		},
	};
	return errors::noentry;
};

fn empty_dir() directory = directory {
	ents = alloc([null...]: [min_buckets]nullable *inode),
	sz = 0,
};

fn hash_of(name: str) u64 = {
	let h = hash::fnv::fnv64a();
	defer hash::close(h);
	hash::write(h, strings::toutf8(name));
	return hash::fnv::sum64(h);
};

