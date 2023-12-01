# install locations
PREFIX = /usr/local/
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man
SRCDIR = $(PREFIX)/src
STDLIB = $(SRCDIR)/hare/stdlib

# variables used during build
PLATFORM = openbsd
ARCH = x86_64
HAREFLAGS =
HARECFLAGS =
QBEFLAGS =
ASFLAGS =
LDLINKFLAGS = -z nobtcfi

# commands used by the build script
HAREC = harec
QBE = qbe
# OpenBSD: gas is in the binutils package. as from the base system is too old.
AS = gas
LD = cc
SCDOC = scdoc

# build locations
HARECACHE = .cache
BINOUT = .bin

# variables that will be embedded in the binary with -D definitions
HAREPATH = $(SRCDIR)/hare/stdlib:$(SRCDIR)/hare/third-party
VERSION=$$(./scripts/version)

AARCH64_AS=aarch64-gas
AARCH64_CC=aarch64-cc
AARCH64_LD=aarch64-cc

RISCV64_AS=riscv64-gas
RISCV64_CC=riscv64-cc
RISCV64_LD=riscv64-cc

X86_64_AS=gas
X86_64_CC=cc
X86_64_LD=cc
