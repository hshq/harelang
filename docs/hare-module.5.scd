hare-module(5)

# NAME

hare-module - Hare module layout

# DESCRIPTION

Hare modules are represented as directories in the filesystem. A directory is a
valid Hare module if it contains at least one Hare source file (with the file
extension *.ha*), or if it contains a file named *README*.

All files which end in *.ha*, *.s*, and *.o* are treated as inputs to the
module, and are respectively treated as Hare sources, assembly sources, and
objects to be linked into the final binary.

The list of files considered eligible may be filtered by build tags (see *BUILD
TAGS* below). The format for the filename is _name_[_tagset_]._ext_, where the
_name_ is user-defined, the _ext_ is either *ha*, *s*, or *o*, and a tagset (see
*BUILD TAGS*) is optionally provided after the name. A file will only be
included if all tags included (with +) in the tagset are present, and no tags
excluded (with -) in the tagset are present.

Only one file for a given combination of _name_ and _ext_ will be selected for
the build; the file selected is the one with the most tag specifiers. If there
are two or more such files, the build driver will error out.

For example, if the following files are present in a directory:

- foo.ha
- bar.ha
- bar+linux.ha
- bar+plan9.ha
- baz+x86_64.s
- bat-x86_64.ha

If the build tags are +linux+x86_64, then the files which are included in the
module are foo.ha, bar+linux.ha, and baz+x86_64.s. If the following files are
added:

- meep+linux-libc.ha
- meep+linux+x86_64.ha

then the build driver will error out, unless +libc is added to the build tags.

Additionally, subdirectories in a module will be considered part of that module
if their name consists only of a tagset, e.g. "+linux" or "-x86_64". A directory
with only a name (but without a tagset, e.g. "example") is considered a
submodule, and as such must be imported separately. For example, "foo::bar"
refers to foo/bar/. If a directory name contains both a name and a tagset, the
build driver will error out.

# DEPENDENCY RESOLUTION

The "use" directives in each Hare source file used as an input to
*hare-build*(1), *hare-run*(1), or *hare-test*(1) are scanned and used to
determine the dependencies for a program. This process is repeated for each
dependency to obtain a complete dependency tree.

Dependencies are searched for by examining first the current working directory,
then each component of the *HAREPATH*, which is a list of paths separated by
colons. *HAREPATH* is obtained from the environment variable of the same name.
If the environment variable is unset, a default value is used, which can be
viewed with the *hare version -v* command. Typically, it is set to include the
path to the standard library installed on the system, as well as a
system-provided location for third-party modules installed via the system
package manager.

*hare-deps*(1) may be used to print the dependency tree of a Hare module.

# BUILD TAGS

Build tags allow you to add constraints on what features or platforms are
enabled for your build. A tag is a name, consisting of characters which aren't
any of '+', '-', or '.', and a '+' or '-' prefix to signal inclusivity or
exclusivity.

To add or remove build tags, use the *-T* flag. For example, *-T +foo-bar* will
add the 'foo' tag and remove the 'bar' tag.

Some tags are enabled by default, enabling features for the host platform. You
can view the default tagset by running *hare version -v*. To remove all default
tags, use *-T^*.

# SEE ALSO

*hare*(1), *hare-build*(1), *hare-run*(1), *hare-test*(1)
