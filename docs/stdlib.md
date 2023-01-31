# Hare stdlib mandate

The Hare standard library shall provide:

2. An interface to the host operating system
3. Implementations of broadly useful algorithms
4. Implementations of broadly useful formats and protocols
1. Useful features to complement Hare language features
5. Introspective meta-features for Hare-aware programs

Each of these services shall:

1. Have a concise and straightforward interface
2. Correctly and completely implement the useful subset of the required behavior*
3. Provide complete documentation for each exported symbol
4. Be sufficiently tested to provide confidence in the implementation

\* This means read the RFC before you start writing the code

Some examples of on-topic features include:

## Language features

- Memory allocation
- High-level string manipulation (e.g. concat, replace, split)
- High-level slice manipulation (e.g. sort)
- Test harness and testing support code

## Introspection

- Hare lexing, parsing (and unparsing), and type checking
- ELF, DWARF
- Stack unwinding

## Operating system interface

- I/O support
- Filesystem access
- Sockets

## Useful algorithms

- Sorting, searching
- Cryptography
- Hashing
- Compression
- Date & time support
- Regex

## Useful formats & protocols

- Internet protocol suite
- INI
- tar, zip, cpio
- MIME

# Conventions

See also the [Hare style guide](https://harelang.org/style/)

1. Tagged unions should be written from most to least common case, which
   generally puts the error cases last.
2. Prefer to design APIs which avoid allocation if it can be done without being
   at the expense of good API design.
3. Whatever the semantics, document the allocation and lifetime behaviors and
   expectations of each function to which they apply.
