# Hare release policy

Hare ships quarterly releases as we work towards Hare 1.0. Releases use the
versioning scheme 0.**YY**.**Q**, where YY is the two-digit release year and Q
is the quarter number (from zero); so the release in Q1 2024 is 0.24.0.

The Hare toolchain's chief dependency is [qbe]. Each Hare version is pinned to a
specific qbe release, which is documented in the release notes corresponding to
that Hare version.

[qbe]: https://c9x.me/compile/

The current release manager is Drew DeVault.

## Breaking changes

Breaking changes to the standard library which are included in each release are
documented in the release notes. Authors of such changes are encouraged to
include a detailed summary of the breaking change in their commit message, for
example:

```
strings: rename pad functions per convention

The following functions in strings:: have been renamed:

* strings::padstart renamed to strings::lpad
* strings::padend renamed to strings::rpad

This is a breaking change.
```

The release manager will collect breaking changes and summarize them in
the release notes for affected versions, providing instructions for affected
users to update their code. If possible, an automated migration procedure will
be prepared on a best-effort basis.

## Release process

One or two weeks prior to the start of each financial quarter, the release
manager will prepare a release branch named "v0.**YY**.**Q**" cut from the
latest master branch, and tag 0.YY.Q-rc1 from this branch, notifying hare-dev
with a preliminary changelog.

Each week following rc1, the release manager will make a judgement call on the
release's quality based on feedback from the community; if the release is not
ready then any additional bugfixes will be cherry-picked from master and rcN+1
tagged. If the release is determiend to be ready, 0.YY.Q is tagged and the
release notes are posted to hare-announce.

## Extended library

The extended library will ship tagged releases which track Hare releases.
However, the extended library does not necessarily change often; in a given
quarter most extended libraries will not have received any patches. As such, new
releases for the extlib are only tagged upon request, or if necessity demands
(such as when updated to address a breaking change).
