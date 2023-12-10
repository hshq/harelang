haredoc(5)

# NAME

haredoc - Hare documentation format

# DESCRIPTION

Hare documentation is written in a simple markup language. *haredoc*(1) will
display the documentation literally, without any additional formatting. Other
tools may format Hare documentation into other formats.

Text may be written normally, broken into several lines to conform to the
80-column limit. To begin a new paragraph, insert an empty line.

References to other declarations and modules may be written in brackets, like
this: [[os::stdout]]. References to modules should include a trailing :: in the
identifier: [[os::exec::]].

A bulleted list can be started by opening a line with "-", optionally preceded
by a space. Each line opened like this begins a new list item. To complete the
list, insert an empty line.

Code samples may be used by starting a line with a single tab, optionally
preceded by a space.

This markup language is extracted from Hare comments preceding exported symbols
in your source code, and from a file named "README" in your module directory, if
present.

# EXAMPLE

```
// Foos the bars. See also [[foobar]].
//
// If you instead want to bar the foos, use one of the functions in
// [[bar::foo::]].
//
// - First, the bars are obtained.
// - They are then fooed.
// - Finally, the result is returned.
//
//      let x = example();
//      assert(x == 0);
export fn example() int = 0;
```

# NOTES

It's expected that tools which parse documentation for the purpose of converting
it into another format will perform additional processing to decouple the
content from its original textual representation:

- Line breaks within a paragraph or list item should be ignored.
- Repeated whitespace outside of a code sample should be collapsed.
- Multiple code samples separated by empty lines should be collapsed into one
  code sample, so the empty lines are moved into the code sample itself.

*hare::parse::doc::* in the standard library handles all of this processing for
you.

Parsers are permitted (and encouraged) to error out on invalid input, such as a
malformed or unterminated [[reference]].

# SEE ALSO

*haredoc*(1)
