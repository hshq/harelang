hare-build(1)

# NAME

hare build - compile a Hare program or module

# SYNOPSIS

*hare build* [-hFqv]++
	[-a _arch_]++
	[-D _ident[:type]=value_]++
	[-j _jobs_]++
	[-L _libdir_]++
	[-l _libname_]++
	[-N _namespace_]++
	[-o _path_]++
	[-R]++
	[-T _tagset_]++
	[-t _type_]++
	[_path_]

# DESCRIPTION

; TODO: Decide on and document driver exit statuses
*hare build* compiles a Hare program or module. The _path_ argument is a path to
a Hare source file or to a directory which contains a Hare module (see
*hare-module*(5)). If no path is given, the Hare module contained in the current
working directory is built.

# OPTIONS

*-h*
	Print the help text.

*-F*
	Build for freestanding (non-hosted) environment. See *FREESTANDING
	ENVIRONMENT*.

*-q*
	Outside of errors, don't write anything to stdout while building.

*-v*
	Enable verbose logging. Specify twice to increase verbosity.

*-a* _arch_
	Set the desired architecture for cross-compiling. See *ARCHITECTURES*
	for supported architecture names.

*-D* _ident[:type]=value_
	Define a constant in the type system. _ident_ is parsed as a Hare
	identifier (e.g. "foo::bar::baz"), _type_ as a Hare type (e.g. "str" or
	"struct { x: int, y: int }"), and _value_ as a Hare expression (e.g.
	"42"). Take care to address any necessary escaping to avoid conflicts
	between your shell syntax and Hare syntax.

*-j* _jobs_
	Set the maximum number of jobs to execute in parallel. The default is
	the number of processors available on the host.

*-L* _libdir_
	Add a directory to the linker library search path.

*-l* _libname_
	Link with the named system library. The name is passed directly to the
	linker. Linking with any library will also link with *libc*(7) and add
	the +libc tag to the default build tags (see *BUILD TAGS* in
	*hare-module*(5)).

*-N* _namespace_
	Override the namespace for the module.

*-o* _path_
	Set the output file to the given path. Setting the path to *-* causes
	output to be written to stdout.

*-R*
	Build in release mode. In debug mode (the default), the debug:: module
	is imported as a dependency, which automatically installs a number of
	runtime debugging features in your executable. See this module's
	documentation for details on these features.

*-T* _tagset_
	Set or unset build tags. See *BUILD TAGS* in *hare-module*(5).

*-t* _type_
	Set the build type. _type_ should be one of s, o, or bin, for assembly,
	compiled object, or compiled binary, respectively. The default build
	type is compiled binary.

# ARCHITECTURES

The *-a* flag is used for cross-compilation to a target architecture different
from the host architecture. The following architectures are currently supported:

- aarch64
- riscv64
- x86_64

The system usually provides reasonable defaults for the *AR*, *AS*, *LD*, and
*CC* tools based on the desired target. However, you may wish to set these
variables yourself to control the cross toolchain in use.

# FREESTANDING ENVIRONMENT

If run with *-F*, hare build will target a freestanding environment. This has
the following effects:

- No constraints are imposed on the signature of "main"
- Specifying external libraries with *-l* will *not* automatically:
	- Link with libc (add *-lc* manually if required)
	- Add the +libc flag (add *-T+libc* manually if required)
	- Use the C compiler for linking (use *LD=cc* if required)

# ENVIRONMENT

The following environment variables affect *hare build*'s execution:

|[ *HARECACHE*
:< The path to the build cache. Defaults to *$XDG_CACHE_HOME/hare*, or
   *~/.cache/hare* if *$XDG_CACHE_HOME* isn't set.
|  *HAREPATH*
:  The list of directories to search for module dependencies in. See
   *hare-module*(5).
|  *NO_COLOR*
:  Disables all color output when set to a non-empty string.
|  *HAREC_COLOR*
:  Disables color output for *harec* when set to 0, enables it when set to any
   other value. This overrides *NO_COLOR*.
|  *HAREC*
:  Name of the *harec* command to use.
|  *HARECFLAGS*
:  Additional flags to pass to *harec*.
|  *QBE*
:  Name of the *qbe* command to use.
|  *QBEFLAGS*
:  Additional flags to pass to *qbe*.
|  *AR*
:  Name of the *ar*(1) command to use.
|  *ARFLAGS*
:  Additional flags to pass to *ar*(1).
|  *AS*
:  Name of the *as*(1) command to use.
|  *ASFLAGS*
:  Additional flags to pass to *as*(1).
|  *LD*
:  Name of the *ld*(1) command to use.
|  *LDLINKFLAGS*
:  Additional flags to pass to *ld*(1).
|  *CC*
:  Name of the *cc*(1) command to use when linking external libraries.
|  *LDFLAGS*
:  Additional linker flags to pass to *cc*(1).

# SEE ALSO

*hare-run*(1), *hare-test*(1), *hare-module*(5), *ar*(1), *as*(1), *cc*(1),
*ld*(1)
