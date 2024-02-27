# The Hare programming language

Hare is a systems programming language.

## Installation

For information about bootstrapping a working Hare toolchain from scratch, see
[Hare Installation][5] on the website.

[5]: https://harelang.org/documentation/install/

## Contributing

All contributors are required to "sign-off" their commits (using `git commit
-s`) to indicate that they have agreed to the [Developer Certificate of
Origin][dco], reproduced below.

[dco]: https://developercertificate.org/

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
1 Letterman Drive
Suite D4700
San Francisco, CA, 94129

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

Please [send patches](https://git-send-email.io) to the [hare-dev][hare-dev]
mailing list to send your changes upstream.

[hare-dev]: https://lists.sr.ht/~sircmpwn/hare-dev

## Licensing

We are not your lawyer, but here is a simple explanation of the intention behind
the Hare licenses.

The Hare standard library is available under the terms of the Mozilla Public
License (MPL). You can freely link to the standard library with software
distributed under any license, but if you modify the standard library, you must
release your derivative works under the MPL as well.

The executables - the build driver, hare, and the compiler, harec, are available
under the GPL 3.0 (but *not* any later version). This permits free use and
redistribution, but any changes to it require you to share the derivative work
under the terms of the GPL. It is stricter than the MPL; if you link to the
compiler or build driver code from a third-party program it will require you to
release the third-party code as well.

In short, you can write programs in Hare which use the standard library and
distribute those programs under any terms you wish. However, if you modify Hare
itself, you must share your changes as well.

The Hare specification is licensed much more strictly: CC-BY-ND. This license
allows free redistribution of the document, but prohibits derivative works
entirely. The purpose is to prevent the proliferation of vendor extensions to
the language itself. However, these terms only apply to the specification
itself: if you use the specification to write an implementation of the Hare
language, you are not restricted in how you license your work.
