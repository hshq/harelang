# The Hare programming language [![builds.sr.ht status](https://builds.sr.ht/~sircmpwn/hare/commits.svg)](https://builds.sr.ht/~sircmpwn/hare/commits?)

Hare is a systems programming language and **a work-in-progress**.

## Principles

1. Trust the programmer.
2. Provide tools the programmer may use when they don't trust themselves.
3. Prefer explicit behavior over implicit behavior.
4. A good program must be both correct and simple.

## Early development secrecy

Hello, onlooker! Please keep this project a secret. Feel free to mess around
with it and send feedback (we're in #hare on irc.freenode.net), but please keep
it to yourself. We don't want to announce this project until it's much, much
more mature.

Ask in the IRC channel to get access to the private bug tracker and mailing
lists.

## Status

This is a work in progress! The process for bootstrapping Hare is as follows:

1. Write the [bootstrap compiler][0] in C, and a [specification][1] which
   describes the language.
2. Write the [build driver][2] in Hare, and at least as much of the
   [standard library][3] which is necessary to make it work.
3. Write the hosted compiler in Hare. At this point, Hare is fully bootstrapped.
4. Expand the standard library until it's useful for general purpose systems
   programming. Write programs in Hare. Provide benefit to society.

Right now, stage 1 is mostly complete. We've started on stage 2, and we're
closing loose ends in stage 1 as we run into blockers during the development of
stage 2.

[0]: https://git.sr.ht/~sircmpwn/harec
[1]: https://harelang.org/specification
[2]: https://git.sr.ht/~sircmpwn/hare
[3]: https://git.sr.ht/~sircmpwn/stdlib

Explanation of terms:

- bootstrap compiler: a Hare compiler written in C, primarily used for the
  purpose of bringing up a working Hare toolchain from scratch.
- hosted compiler: a more sophisticted Hare compiler, written in Hare,
  designed to be the compiler used for day-to-day langauge use.
- build driver: similar to make, its purpose is to collect source files, track
  their dependencies, and build them into Hare programs.

## Getting the code

This repository is the build driver, i.e. the source for the "hare" command. The
other important repositories include the hosted compiler, bootstrap compiler,
and the standard library. You can browse all of the source code on the [sr.ht
project page][4].

[4]: https://sr.ht/~sircmpwn/hare/

For information about bootstrapping a working Hare toolchain from scratch, see
[Hare Installation][5] on the website.

[5]: https://harelang.org/installation/
