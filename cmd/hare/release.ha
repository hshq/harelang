use errors;
use fmt;
use fs;
use io;
use os::exec;
use os;
use strconv;
use strings;
use temp;
use unix;

type increment = enum {
	MAJOR,
	MINOR,
	PATCH,
};

type modversion = (uint, uint, uint);
type git_error = !exec::exit_status;
type badversion = !void;
type release_error = !(exec::error | io::error | fs::error | errors::error
	| badversion | git_error);

fn parseversion(in: str) (modversion | badversion) = {
	const items = strings::split(in, ".");
	defer free(items);
	if (len(items) != 3) {
		return badversion;
	};
	let major = 0u, minor = 0u, patch = 0u;
	const ptrs = [&major, &minor, &patch];
	for (let i = 0z; i < len(items); i += 1) {
		*ptrs[i] = match (strconv::stou(items[i])) {
		case u: uint =>
			yield u;
		case =>
			return badversion;
		};
	};
	return (major, minor, patch);
};

fn do_release(incr: increment, dryrun: bool) (void | release_error) = {
	// XXX: If we were feeling REALLY fancy we could run the diff and
	// automatically detect new functions/types/etc (minor bump), breaking
	// changes (major bump), or neither (patch bump). I don't feel that
	// fancy, however.

	// TODO:
	// - Run hare test
	// - Run git tag -a with release notes pre-filled
	// - Generate & sign tarballs as git notes
	checkbranch()?;
	checkstatus()?;
	git_runcmd("fetch")?;
	checkbehind()?;

	// TODO: Detect if distance from the last tag is zero commits
	const lasttag = match (git_readcmd("describe", "--abbrev=0")) {
	case git_error =>
		return do_initial_release();
	case err: release_error =>
		return err;
	case s: str =>
		yield strings::rtrim(s);
	};
	defer free(lasttag);

	const current = parseversion(lasttag)?;
	const new: modversion = switch (incr) {
	case increment::MAJOR =>
		yield (current.0 + 1, 0, 0);
	case increment::MINOR =>
		yield (current.0, current.1 + 1, 0);
	case increment::PATCH =>
		yield (current.0, current.1, current.2 + 1);
	};
	const newtag = fmt::asprintf("{}.{}.{}", new.0, new.1, new.2);
	defer free(newtag);
	const range = fmt::asprintf("{}..HEAD", lasttag);
	defer free(range);

	const dir = temp::dir();
	defer os::rmdirall(dir)!;
	const changelog = temp::named(os::cwd, dir, io::mode::WRITE)?;
	const clfile = changelog.0, changelog = changelog.1;
	fmt::fprintfln(clfile, "# Version {}", newtag)?;
	fmt::fprintln(clfile, "# TODO: Fill in more stuff here")?;
	shortlog(clfile, range)?;

	git_runcmd("tag", "-aeF", changelog, newtag)?;
};

fn do_initial_release() (void | release_error) = {
	fmt::fatal("TODO: Tag initial release");
};

fn checkbranch() (void | release_error) = {
	const default_branch = get_defaultbranch()?;
	defer free(default_branch);
	const current_branch = get_currentbranch()?;
	defer free(current_branch);
	if (default_branch != current_branch) {
		fmt::errorfln(
			"Warning! You do not have the {} branch checked out.",
			default_branch)!;
	};
};

fn checkstatus() (void | release_error) = {
	const status = strings::rtrim(git_readcmd("status", "-zuno")?);
	defer free(status);
	if (len(status) != 0) {
		fmt::errorln("Warning! You have uncommitted changes.")!;
	};
};

fn checkbehind() (void | release_error) = {
	const upstream = match (git_readcmd("rev-parse", "HEAD@{upstream}")) {
	case git_error =>
		// Fails if there is no upstream, in which case we don't need to
		// bother checking.
		return;
	case err: release_error =>
		return err;
	case s: str =>
		yield s;
	};
	defer free(upstream);
	const head = git_readcmd("rev-parse", "HEAD")?;
	defer free(head);
	if (upstream == head) {
		return;
	};
	match (git_runcmd("merge-base", "--is-ancestor", "HEAD@{upstream}", "HEAD")) {
	case git_error =>
		fmt::errorln("Warning! Your local branch is behind the upstream branch.")!;
	case err: release_error =>
		return err;
	case => void;
	};
};

fn shortlog(out: io::file, what: str) (void | release_error) = {
	const cmd = exec::cmd("git", "shortlog", "--no-merges", what)?;
	exec::addfile(&cmd, out, os::stdout_file);
	const proc = exec::start(&cmd)?;
	const status = exec::wait(&proc)?;
	exec::check(&status)?;
};

fn git_runcmd(args: str...) (void | release_error) = {
	const cmd = exec::cmd("git", args...)?;
	const proc = exec::start(&cmd)?;
	const status = exec::wait(&proc)?;
	return exec::check(&status)?;
};

fn git_readcmd(args: str...) (str | release_error) = {
	const pipe = unix::pipe()?;
	defer io::close(pipe.0);
	const cmd = exec::cmd("git", args...)?;
	exec::addfile(&cmd, pipe.1, os::stdout_file);
	const proc = exec::start(&cmd)?;
	io::close(pipe.1);
	const result = io::drain(pipe.0)?;
	const status = exec::wait(&proc)?;
	exec::check(&status)?;
	return strings::fromutf8(result);
};

fn get_defaultbranch() (str | release_error) = {
	const branch = git_readcmd("config",
		"--default", "master", "init.defaultBranch")?;
	return strings::rtrim(branch);
};

fn get_currentbranch() (str | release_error) = {
	return strings::rtrim(git_readcmd("branch", "--show-current")?);
};
