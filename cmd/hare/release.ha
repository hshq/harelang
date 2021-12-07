use bufio;
use errors;
use fmt;
use fs;
use io;
use os::exec;
use os;
use path;
use strconv;
use strings;
use temp;

type increment = enum {
	MAJOR,
	MINOR,
	PATCH,
};

type modversion = (uint, uint, uint);
type git_error = exec::exit_status;
type badversion = !void;
type release_error = !(exec::error | io::error | fs::error | errors::error
	| badversion | git_error);

const changelog_template: str = "# This is the changelog for your release. It has been automatically pre-filled
# with the changes from version {} via git-shortlog(1). Please review the
# changelog below and, if necessary, add a brief note regarding any steps
# required for the user to upgrade this software. It is recommended to keep this
# brief and clinical, so readers can quickly understand what's changed, and to
# save marketing comments for a separate release announcement.
#
# Any lines which begin with \"#\", like this one, are for your information
# only, and will be removed from the final changelog. Edit this file to your
# satisfaction, then save and close your editor.
#
{} version {}
";

const initial_template: str = "# These are the release notes for the initial release of {0}.
#
# Any lines which begin with \"#\", like this one, are for your information
# only, and will be removed from the final release notes. Edit this file to your
# satisfaction, then save and close your editor.
#
{0} version {1}
";

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
		case let u: uint =>
			yield u;
		case =>
			return badversion;
		};
	};
	return (major, minor, patch);
};

fn do_release(
	next: (increment | modversion),
	dryrun: bool,
) (void | release_error) = {
	// XXX: If we were feeling REALLY fancy we could run the diff and
	// automatically detect new functions/types/etc (minor bump), breaking
	// changes (major bump), or neither (patch bump). I don't feel that
	// fancy, however.

	// TODO: Run hare test
	checkbranch()?;
	checkstatus()?;
	git_runcmd("fetch")?;
	checkbehind()?;

	// TODO: Detect if distance from the last tag is zero commits
	const lasttag = match (git_readcmd("describe", "--abbrev=0")) {
	case git_error =>
		return do_initial_release(next);
	case let err: release_error =>
		return err;
	case let s: str =>
		yield strings::rtrim(s);
	};
	defer free(lasttag);

	const key = choosekey()?;
	defer free(key);

	const current = parseversion(lasttag)?;
	const new = nextversion(current, next);
	const newtag = fmt::asprintf("{}.{}.{}", new.0, new.1, new.2);
	defer free(newtag);
	const range = fmt::asprintf("{}..HEAD", lasttag);
	defer free(range);

	const name = path::basename(os::getcwd());
	const dir = temp::dir();
	defer os::rmdirall(dir)!;
	const changelog = temp::named(os::cwd, dir, io::mode::WRITE)?;
	const clfile = changelog.0, changelog = changelog.1;
	defer io::close(clfile);
	fmt::fprintfln(clfile, changelog_template, lasttag, name, newtag)?;
	shortlog(clfile, range)?;

	git_runcmd("tag", "-aeF", changelog, newtag)?;
	signtag(dir, name, newtag, key)?;
	fmt::printfln("Tagged {} version {}. "
		"Use 'git push --follow-tags' to publish the new release.",
		name, newtag)!;
};

fn do_initial_release(ver: (modversion | increment)) (void | release_error) = {
	const ver = match (ver) {
	case let ver: modversion =>
		yield ver;
	case increment =>
		fmt::errorln("Error: cannot increment version number without a previous version to reference.")!;
		fmt::errorln("For the first release, try 'hare release 1.0.0' instead.")!;
		os::exit(1);
	};

	const key = choosekey()?;
	defer free(key);
	const newtag = fmt::asprintf("{}.{}.{}", ver.0, ver.1, ver.2);
	defer free(newtag);

	const name = path::basename(os::getcwd());
	const dir = temp::dir();
	defer os::rmdirall(dir)!;
	const changelog = temp::named(os::cwd, dir, io::mode::WRITE)?;
	const clfile = changelog.0, changelog = changelog.1;
	defer io::close(clfile);
	fmt::fprintfln(clfile, initial_template, name, newtag)?;

	git_runcmd("tag", "-aeF", changelog, newtag)?;
	signtag(dir, name, newtag, key)?;
	fmt::printfln("Tagged {} version {}. "
		"Use 'git push --follow-tags' to publish the new release.",
		name, newtag)!;
};

fn nextversion(
	current: modversion,
	next: (increment | modversion),
) modversion = {
	const next = match (next) {
	case let incr: increment =>
		yield incr;
	case let ver: modversion =>
		return ver;
	};
	switch (next) {
	case increment::MAJOR =>
		return (current.0 + 1, 0, 0);
	case increment::MINOR =>
		return (current.0, current.1 + 1, 0);
	case increment::PATCH =>
		return (current.0, current.1, current.2 + 1);
	};
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
	case let err: release_error =>
		return err;
	case let s: str =>
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
	case let err: release_error =>
		return err;
	case => void;
	};
};

fn shortlog(out: io::file, what: str) (void | release_error) = {
	const cmd = exec::cmd("git", "shortlog", "--no-merges", what)?;
	exec::addfile(&cmd, os::stdout_file, out);
	const proc = exec::start(&cmd)?;
	const status = exec::wait(&proc)?;
	exec::check(&status)?;
};

fn choosekey() (str | release_error) = {
	match (os::getenv("HAREKEY")) {
	case void => void;
	case let name: str =>
		return name;
	};
	const paths = [
		"id_ed25519",
		"id_ecdsa",
		"id_rsa",
		"id_dsa",
	];
	const home = os::getenv("HOME") as str;
	for (let i = 0z; i < len(paths); i += 1) {
		const cand = path::join(home, ".ssh", paths[i]);
		if (os::stat(cand) is fs::error) {
			free(cand);
			continue;
		};
		return cand;
	};
	fmt::errorln("No suitable SSH key found to sign releases with.")!;

	fmt::error("Would you like to generate one now? [Y/n] ")!;
	const line = match (bufio::scanline(os::stdin)?) {
	case io::EOF =>
		fmt::fatal("No suitable key available. Terminating.");
	case let line: []u8 =>
		yield strings::fromutf8(line);
	};
	defer free(line);
	if (line != "" && line != "y" && line != "Y") {
		fmt::fatal("No suitable key available. Terminating.");
	};

	const parent = path::join(home, ".ssh");
	defer free(parent);
	os::mkdirs(parent)?;

	const path = path::join(home, ".ssh", "id_ed25519");
	const cmd = match (exec::cmd("ssh-keygen", "-t", "ed25519", "-f", path)) {
	case let cmd: exec::command =>
		yield cmd;
	case let err: exec::error =>
		fmt::fatal("ssh-keygen: command not found. Is openssh installed?");
	};
	const proc = exec::start(&cmd)?;
	const status = exec::wait(&proc)?;
	exec::check(&status)?;
	fmt::println("You will be prompted to enter your password again to create the release signature.")!;
	return path;
};

fn signtag(tmpdir: str, name: str, tag: str, key: str) (void | release_error) = {
	// This could work without the agent if it were not for the fact that
	// ssh-keygen is bloody stupid when it comes to prompting you for your
	// password.
	const socket = path::join(tmpdir, "agent");
	defer free(socket);
	const agent = exec::cmd("ssh-agent", "-Da", socket)?;
	exec::nullstd(&agent);
	const agent = exec::start(&agent)?;
	defer exec::kill(agent)!;

	const addkey = exec::cmd("ssh-add", key)?;
	exec::setenv(&addkey, "SSH_AUTH_SOCK", socket);
	const addkey = exec::start(&addkey)?;
	const addkey = exec::wait(&addkey)?;
	exec::check(&addkey)?;

	const prefix = fmt::asprintf("--prefix={}-{}/", name, tag);
	defer free(prefix);
	const archive = exec::cmd("git", "archive",
		"--format=tar.gz", prefix, tag)?;
	const ssh = exec::cmd("ssh-keygen",
		"-Y", "sign", "-f", key, "-n", "file")?;
	const note = exec::cmd("git", "notes", "add", "-F", "-", tag)?;
	exec::setenv(&note, "GIT_NOTES_REF", "refs/notes/signatures/tar.gz");

	exec::setenv(&ssh, "SSH_AUTH_SOCK", socket);
	// Squelch "Signing data on standard input" message
	// TODO: It might be better to capture this and print it to stderr
	// ourselves if ssh-keygen exits nonzero, so that the error details are
	// available to the user for diagnosis.
	exec::addfile(&ssh, os::stderr, exec::nullfd);

	const pipe1 = exec::pipe();
	const pipe2 = exec::pipe();
	exec::addfile(&archive, os::stdout_file, pipe1.1);
	exec::addfile(&ssh, os::stdin_file, pipe1.0);
	exec::addfile(&ssh, os::stdout_file, pipe2.1);
	exec::addfile(&note, os::stdin_file, pipe2.0);
	const archive = exec::start(&archive)?;
	const ssh = exec::start(&ssh)?;
	const note = exec::start(&note)?;
	io::close(pipe1.0);
	io::close(pipe1.1);
	io::close(pipe2.0);
	io::close(pipe2.1);
	exec::check(&exec::wait(&archive)?)?;
	exec::check(&exec::wait(&ssh)?)?;
	exec::check(&exec::wait(&note)?)?;
};

fn git_runcmd(args: str...) (void | release_error) = {
	const cmd = exec::cmd("git", args...)?;
	exec::addfile(&cmd, os::stderr, exec::nullfd);
	const proc = exec::start(&cmd)?;
	const status = exec::wait(&proc)?;
	return exec::check(&status)?;
};

fn git_readcmd(args: str...) (str | release_error) = {
	const pipe = exec::pipe();
	defer io::close(pipe.0);
	const cmd = exec::cmd("git", args...)?;
	exec::addfile(&cmd, os::stdout_file, pipe.1);
	exec::addfile(&cmd, os::stderr, exec::nullfd);
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
