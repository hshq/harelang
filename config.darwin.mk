## Install configuration

HAREC_TOOLS = ../harec.git/rt/+darwin

PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man
SRCDIR = $(PREFIX)/src

# Where to install the stdlib tree
STDLIB = $(SRCDIR)/hare/stdlib

# Default HAREPATH
HAREPATH = $(SRCDIR)/hare/stdlib:$(SRCDIR)/hare/third-party

## Build configuration

# Platform to build for
PLATFORM = darwin
ARCH = x86_64

# External tools and flags
HAREC = /usr/local/bin/harec
HARECFLAGS =
QBE = $(HAREC_TOOLS)/qbe.sh
AS = $(HAREC_TOOLS)/as.sh
LD = $(HAREC_TOOLS)/ld.sh
AR = ar
SCDOC = scdoc

# Where to store build artifacts
HARECACHE = .cache
BINOUT = .bin

# Cross-compiler toolchains
AARCH64_AS=aarch64-as
AARCH64_AR=aarch64-ar
AARCH64_CC=aarch64-cc
AARCH64_LD=aarch64-ld

RISCV64_AS=riscv64-as
RISCV64_AR=riscv64-ar
RISCV64_CC=riscv64-cc
RISCV64_LD=riscv64-ld

X86_64_AS=$(AS)
X86_64_AR=/usr/bin/ar
X86_64_CC=/usr/bin/cc
X86_64_LD=$(LD)
