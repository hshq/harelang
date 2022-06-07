## Install configuration

PREFIX = /usr
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man
SRCDIR = $(PREFIX)/src

# Where to install the stdlib tree
STDLIB = $(SRCDIR)/hare/stdlib

# Default HAREPATH
LOCALSRCDIR = /usr/local/src/hare
HAREPATH = $(LOCALSRCDIR)/stdlib:$(LOCALSRCDIR)/third-party:$(SRCDIR)/hare/stdlib:$(SRCDIR)/hare/third-party

## Build configuration

# Platform to build for
PLATFORM = linux
ARCH = x86_64

# External tools and flags
HAREC = harec
HAREFLAGS =
QBE = qbe
AS = as
LD = ld
AR = ar
SCDOC = scdoc

# Where to store build artifacts
HARECACHE = .cache
BINOUT = .bin

# Cross-compiling settings
AARCH64_AS=aarch64-as
AARCH64_AR=aarch64-ar
AARCH64_CC=aarch64-cc
AARCH64_LD=aarch64-ld

RISCV64_AS=riscv64-as
RISCV64_AR=riscv64-ar
RISCV64_CC=riscv64-cc
RISCV64_LD=riscv64-ld

X86_64_AS=x86_64-as
X86_64_AR=x86_64-ar
X86_64_CC=x86_64-cc
X86_64_LD=x86_64-ld
