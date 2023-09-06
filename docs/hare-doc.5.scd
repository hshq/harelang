hare-doc(5)

# NAME

hare-doc - hare documentation format.

# DESCRIPTION

The Hare formatting markup is a very simple markup language. Text may be written
normally, broken into several lines to conform to the column limit. Repeated
whitespace will be collapsed. To begin a new paragraph, insert an empty line.

Links to Hare symbols may be written in brackets, like this: [[os::stdout]]. A
bulleted list can be started by opening a line with "-". To complete the list,
insert an empty line. Code samples may be used by using more than one space
character at the start of a line (a tab character counts as 8 spaces).

This markup language is extracted from Hare comments preceding exported symbols
in your source code, and from a file named "README" in your module directory, if
present.

```
// Foos the bars. See also [[foobar]].
export fn example() int;
```

# SEE ALSO

*hare*(1)
