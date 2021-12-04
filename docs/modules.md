# Hare Modules

*This document is informative. It describes the behavior of the upstream Hare
distribution's build driver, but other Hare implementations may differ, and we
may revise this behavior in the future.*

TODO:

- Describe caching mechanism
- hare.ini considerations and linking to static libraries

The **host** is the machine which is running the build driver and Hare
toolchain. The **target** is the machine which the completed program is expected
to run on. This may not be the same as the host configuration, for example when
**cross-compiling**. The **build driver**, located at `cmd/hare`, orchestrates
this process by collecting the necessary source files to build a Hare program,
resolving its dependencies, and executing the necessary parts of the toolchain
in the appropriate order.

## The build driver and the Hare specification

The Hare language specification is defined at a layer of abstraction that does
not include filesystems, leaving it to the implementation to define how Hare
sources are organized. The upstream Hare distribution maps the concept of a
"module" onto what the spec defines as a *unit*, and each Hare source file in
the filesystem provides what the specification refers to as a *subunit*.

The upstream Hare distribution provides the "hosted" translation environment.
Hare programs prepared for the "freestanding" environment may also be compiled
with the upstream distribution, but the standard library is not used in this
situation.

## Build tags

The upstream distribution defines the concept of a **build tag**, or "tag",
which is an alphanumeric string and an "inclusive" or "exclusive" bit, which is
used to control the list of source files considered for inclusion in a Hare
module.

The environment defines a number of default build tags depending on the target
system it was configured for. For example, a Linux system running on an x86\_64
processor defines +linux and +x86\_64 by default, which causes files tagged
+linux or +x86\_64 to be included, and files tagged -linux or -x86\_64 to be
excluded.

The host configuration defines a set of default build tags, which may be
overridden by specifying an alternate target. The `hare version -v` command
prints out the defaults.

It is important to note that Hare namespaces and build tags are mutually
exclusive grammars, thanks to the fact that the + and - symbols may not appear
in a Hare identifier.

## Locating modules on the filesystem

Each module, identified by its namespace, is organized into "root" directory,
where all of its source files may be found, either as members or descendants.
This directory corresponds to a file path which is formed by replacing the
namespace delimiters (`::`) with the path separator for the target host system
(e.g. `/`). This forms a relative path, which is then applied to each of several
possible **source roots**.

A source root is a directory which forms the root of a hierarchy of Hare modules
and their sources. This directory may also itself be a module, namely the **root
module**: it provides the unit for the empty namespace, where, for example, the
"main" function can be found. Generally speaking, there will be at least two
source roots to choose from: the user's program, and the standard library.

The current working directory (`.`) is always assigned the highest priority. If
the `HAREPATH` environment variable is set, it specifies a colon-delimited (`:`)
list of additional candidates in descending order of preference. If unset, a
default value is used, which depends on the host configuration, generally
providing at least the path to the standard library's installation location, as
well the installation location of third-party Hare modules. The `hare version
-v` command prints out the defaults configured for this host.

Each of these source roots is considered in order of precedence by concatenating
the source root path and the relative path of the desired module, and checking
if a **valid** Hare module is present. A module is considered valid if it
contains any regular files, or symlinks to regular files, whose names end in
`.ha` or `.s`; or if it contains any directories, or symlinks to directories;
whose names begin with `+` or `-` and which would also be considered valid under
these criteria, applied recursively.

The user's program, or any dependency, may *shadow* a module from the standard
library (or another dependency) by providing a suitably named directory in a
source root with a higher level of precedence.

## Assembling the list of source files

A source file is named with the following convention:

`<name>[<tags...>].<ext>`

The \< and \> symbols denote a required parameter, and \[ and \[ denote optional
parameters. Some example names which follow this convention are:

- `main.ha`
- `pipe+linux.ha`
- `example-freebsd.ha`
- `longjmp.s`
- `foo+linux-x86_64.ha`

The build driver examines the list of files in a given module's root directory,
eliminating those with incompatible build tags, and produces a list of
applicable files. Once files with incompatible build tag have been eliminated,
only one file for a given "name" may be provided, such that a module with the
files `hello.ha` and `hello.s` is invalid. Only the "ha" and "s" extensions are
used, respectively denoting Hare sources and assembly sources.

If any sub-directories of the module's root directory begin with `-` or `+`,
they are treated as a set of build tags and considered for their compatibility
with the build driver's active set of build tags. If compatible, the process is
repeated within that directory, treating its contents as members of the desired
module.

## Semantics of specific tools

A summary of how the mechanisms documented above are applied by each tool is
provided.

### hare build, hare run

The input to this command is the location of the root module for the Hare
program to be built or run. If the path provided identifies a file, that file is
used as the sole input file for the root module. If the path identifies a
directory, the directory is used as the root directory for the root module,
whose source files are assembled according to the algorithm described above.

### hare test

`hare test` walks the current source root (i.e. the current working directory)
by recursively checking if that directory, and every directory which is a
descendant of it, is a valid Hare module. Each of these modules is compiled with
the special +test build tag defined. Dependencies of these modules are also
built, but with the +test tag unspecified, with the exception of the rt module,
which provides a special test runner in this mode. The resulting executable is
executed, which causes all of the `@test` functions in the current source root
to be executed.

The command line arguments for hare test, if given at all, are interpreted by
rt+test as a list of namespace wildcards (see [fnmatch]) defining which subsets
of the test suite to run.

[fnmatch]: https://docs.harelang.org/fnmatch

### haredoc

The `haredoc` command accepts a list of identifiers to fetch documentation for,
using the same identifiers which the user might use in a Hare source file to
utilize the corresponding module or declaration.

The desired identifier is converted to a path. If this path refers to a
directory which is a valid Hare module, documentation for that module is shown.
If that path refers to a directory which is not a valid Hare module, it is
walked to determine if any of its sub-directories are valid Hare modules; if so,
a list of those sub-directories is shown. If the path does not exist, the most
specific component of the identifier is removed, and looked up as a module,
within which the least-significant component is looked up as a declaration
exported from that module. If the module or this declaration still is not found,
the identifier is deemed unresolvable and an error is shown.
