hare(1)

# NAME

hare - compiles, runs, and tests Hare programs

# SYNOPSIS

*hare* build [-hqv]++
	[-a _arch_]++
	[-D _ident[:type]=value_]++
	[-j _jobs_]++
	[-L _libdir_]++
	[-l _libname_]++
	[-N _namespace_]++
	[-o _path_]++
	[-T _tagset_]++
	[-t _type_]++
	[_path_]

*hare* cache [-hc]

*hare* deps [-hd] [-T _tagset_] [_path_|_module_]

*hare* run [-hqv]++
	[-a _arch_]++
	[-D _ident[:type]=value_]++
	[-j _jobs_]++
	[-L _libdir_]++
	[-l _libname_]++
	[-T _tagset_]++
	[_path_ [_args_...]]

*hare* test [-hqv]++
	[-a _arch_]++
	[-D _ident[:type]=value_]++
	[-j _jobs_]++
	[-L _libdir_]++
	[-l _libname_]++
	[-o _path_]++
	[-T _tagset_]++
	[_path_]

*hare* version [-hv]

# DESCRIPTION

; TODO: Decide on and document driver exit statuses
*hare build* compiles a Hare program into an executable. The _path_ argument is
a path to a Hare source file or a directory which contains a Hare module (see
*MODULES* below). If no path is given, the Hare module contained in the current
working directory is built.

*hare cache* displays information about the build cache.

*hare deps* displays the dependency graph of a Hare program. The _path_ argument
is equivalent in usage to *hare build*.

*hare run* compiles and runs a Hare program. The _path_ argument is equivalent
in usage to *hare build*. If provided, any additional _args_ are passed to the
Hare program which is run. os::args[0] is set to the _path_ argument.

*hare test* compiles and runs tests for Hare code. All Hare modules in the
current working directory are recursively discovered, built, and their tests
made eligible for the test run. If the _tests_ argument is omitted, all tests
are run. Otherwise, each argument is interpreted as a *glob*(7) pattern, giving
the names of the tests that should be run. *hare test* adds the +test tag to the
default build tags.

*hare version* prints version information for the *hare* program. If *-v* is
supplied, it also prints information about the build parameters. The output
format is consistent for machine reading: the first line is always
"hare $version". Subsequent lines give configuration values in the form of a
name, value, and optional context, separated by tabs.

# OPTIONS

## hare build

*-h*
	Prints the help text.

*-q*
	Outside of errors, don't write anything to stdout while building.

*-v*
	Enable verbose logging. Specify twice to increase verbosity.

*-a* _arch_
	Set the desired architecture for cross-compiling. See *ARCHITECTURES*
	for supported architecture names.

*-D* _ident[:type]=value_
	Passed to *harec*(1) to define a constant in the type system. _ident_ is
	parsed as a Hare identifier (e.g. "foo::bar::baz"), _type_ as a Hare
	type (e.g. "str" or "struct { x: int, y: int }"), and _value_ as a Hare
	expression (e.g. "42"). Take care to address any necessary escaping to
	avoid conflicts between your shell syntax and Hare syntax.

*-j* _jobs_
	Defines the maximum number of jobs which *hare* will execute in
	parallel. The default is the number of processors available on the host.

*-L libdir*
	Add directory to the linker library search path.

*-l* _libname_
	Link with the named system library. The name is passed to
	*pkg-config --libs* (see *pkg-config*(1)) to obtain the appropriate
	linker flags.

*-N* _namespace_
	Override the namespace for the module. 

*-o* _path_
	Set the output file to the given path.

*-T* _tagset_
	Sets or unsets build tags. See *CUSTOMIZING BUILD TAGS*.

*-t* _type_
	Set the build type. Should be one of s/o/bin, for assembly, compiled
	object, or compiled binary, respectively.

## hare cache

*-h*
	Prints the help text.

*-c*
	Clears the cache.

## hare deps

*-h*
	Prints the help text.

*-d*
	Print dependency graph as a dot file for use with *graphviz*(1).

*-T* _tags_
	Sets or unsets build tags. See *CUSTOMIZING BUILD TAGS*.

## hare run

*-h*
	Prints the help text.

*-q*
	Outside of errors, don't write anything to stdout while building.

*-v*
	Enable verbose logging. Specify twice to increase verbosity.

*-a* _arch_
	Set the desired architecture for cross-compiling. See *ARCHITECTURES*
	for supported architecture names.

*-D* _ident[:type]=value_
	Passed to *harec*(1) to define a constant in the type system. _ident_ is
	parsed as a Hare identifier (e.g. "foo::bar::baz"), _type_ as a Hare
	type (e.g. "str" or "struct { x: int, y: int }"), and _value_ as a Hare
	expression (e.g. "42"). Take care to address any necessary escaping to
	avoid conflicts between your shell syntax and Hare syntax.

*-j* _jobs_
	Defines the maximum number of jobs which *hare* will execute in
	parallel. The default is the number of processors available on the host.

*-l* _name_
	Link with the named system library. The name is passed to
	*pkg-config --libs* (see *pkg-config*(1)) to obtain the appropriate
	linker flags.

*-L libdir*
	Add directory to the linker library search path.

*-T* _tags_
	Sets or unsets build tags. See *CUSTOMIZING BUILD TAGS*.

## hare test

*-h*
	Prints the help text.

*-q*
	Outside of errors, don't write anything to stdout while building.

*-v*
	Enable verbose logging. Specify twice to increase verbosity.

*-a* _arch_
	Set the desired architecture for cross-compiling. See *ARCHITECTURES*
	for supported architecture names.

*-D* _ident[:type]=value_
	Passed to *harec*(1) to define a constant in the type system. _ident_ is
	parsed as a Hare identifier (e.g. "foo::bar::baz"), _type_ as a Hare
	type (e.g. "str" or "struct { x: int, y: int }"), and _value_ as a Hare
	expression (e.g. "42"). Take care to address any necessary escaping to
	avoid conflicts between your shell syntax and Hare syntax.

*-j* _jobs_
	Defines the maximum number of jobs which *hare* will execute in
	parallel. The default is the number of processors available on the host.

*-l* _name_
	Link with the named system library. The name is passed to
	*pkg-config --libs* (see *pkg-config*(1)) to obtain the appropriate
	linker flags.

*-L libdir*
	Add directory to the linker library search path.

*-T* _tags_
	Adds additional build tags. See *CUSTOMIZING BUILD TAGS*.

*-X* _tags_
	Unsets build tags. See *CUSTOMIZING BUILD TAGS*.

## hare version

*-h*
	Prints the help text.

*-v*
	Show build parameters.

# MODULES

The _path_ argument to *hare build* and *hare run* are used to identify the
inputs for the build. If this path is a file, it is treated as a single Hare
source file. If it is a directory, the directory is treated as a module, and is
placed in the global namespace for the build.

All files which end in *.ha*, *.s*, and *.o* are treated as inputs to the
module, and are respectively treated as Hare sources, assembly sources, and
objects to be linked into the final binary. There must either be at least one
Hare source or a file named 'README' in the module's root directory.

The list of files considered eligible may be filtered by build tags. The format
for the filename is _name_[+_tags_]._ext_, where the _name_ is user-defined, the
_ext_ is either 'ha' or 's', and a list of tags are provided after the name. A
plus symbol ('+') will cause a file to be included only if that tag is present,
and a minus symbol ('-') will cause a file to be excluded if that tag is
present.

Only one file for a given combination of _name_ and _ext_ will be selected for
the build, and among files with eligible tags, the one with the most tag
specifiers is selected. If there are two or more such files, the build driver
will error out.

For example, if the following files are present in a directory:

- foo.ha
- bar.ha
- bar+linux.ha
- bar+plan9.ha
- baz+x86_64.s
- bat-x86_64.ha

If the build tags are +linux+x86_64, then the files which are included in the
module are foo.ha, bar+linux.ha, and baz+x86_64.s.

Additionally, subdirectories in a module will be considered part of that module
if their name consists *only* of a tag set, e.g. "+linux" or "-x86_64". A
directory with a name *and* tag set is never considered as part of any module,
such as "example+linux". A directory with only a name (e.g. "example") is
considered a sub-module of its parent directory and must be imported separately,
so "foo::bar" refers to foo/bar/.

# DEPENDENCY RESOLUTION

The "use" statements in each source file which is used as an input to *hare
build* or *hare run* are scanned and used to determine the dependencies for the
program, and this process is repeated for each dependency to obtain a complete
dependency graph.

Dependencies are searched for by examining first the current working directory,
then each component of the *HAREPATH* environment variable in order, which is a
list of paths separated by colons. The default value of the *HAREPATH* may be
found with the *hare version -v* command. Typically, it is set to include the
path to the standard library installed on the system, as well as a
system-provided storage location for third-party modules installed via the
system package manager.

# ARCHITECTURES

The *-a* flag for *hare build* is used for cross-compilation, and selects a
architecture different from the host to target. The list of supported
architectures is:

- aarch64
- riscv64
- x86_64

The system usually provides reasonable defaults for the *AR*, *AS*, and *LD*
tools based on the desired target. However, you may wish to set these variables
yourself to control the cross toolchain in use.
; TODO: sysroots

# CUSTOMIZING BUILD TAGS

Build tags allow you to add constraints on what features or platforms are
enabled for your build. A tag is a name, consisting of characters which aren't
any of '+', '-', or '.', and a + or - prefix to signal inclusivity or
exclusivity. See *MODULES* for details on how build tags affect module input
selection.

To add or remove build tags, use the *-T* flag. For example, "-T +foo-bar" will
add the 'foo' tag and remove the 'bar' tag.

Some tags are enabled by default, enabling features for the host platform. You
can view the default tagset by running *hare version -v*. To remove all default
tags, use "-T^".

# ENVIRONMENT

The following environment variables affect *hare*'s execution:

|[ *HARECACHE*
:< The path to the build cache. Defaults to _$XDG_CACHE_HOME/hare_, or
   _~/.cache/hare_ if that doesn't exist.
|  *HAREPATH*
:  See *DEPENDENCY RESOLUTION*.
|  *HAREFLAGS*
:  Applies additional flags to the command line arguments.
|  *HAREC*
:  Name of the *harec*(1) command to use.
|  *QBE*
:  Name of the *qbe*(1) command to use.
|  *QBEFLAGS*
:  Additional flags to pass to *QBE*(1).
|  *AR*
:  Name of the *ar*(1) command to use.
|  *ARFLAGS*
:  Additional flags to pass to *ar*(1).
|  *AS*
:  Name of the *as*(1) command to use.
|  *ASFLAGS*
:  Additional flags to pass to *as*(1).
|  *CC*
:  Name of the *cc*(1) command to use when linking external libraries.
|  *LDFLAGS*
:  Additional linker flags to pass to *cc*(1).
|  *LD*
:  Name of the *ld*(1) command to use.
|  *LDLINKFLAGS*
:  Additional flags to pass to *ld*(1).
|  *CC*
:  Name of the *cc*(1) command to use.
|  *LDFLAGS*
:  Additional flags to pass to *cc*(1).

# SEE ALSO

*harec*(1), *as*(1), *ld*(1), *cc*(1), *hare-doc*(5), *as*(1)
