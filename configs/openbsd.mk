# install locations
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/man
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
# gas is in the "binutils" package; as from the base system is too old. the "gas"
# package also works on all arches except riscv64.
AS = gas
LD = cc
SCDOC = scdoc

# build locations
HARECACHE = .cache
BINOUT = .bin

# variables that will be embedded in the binary with -D definitions
HAREPATH = $(SRCDIR)/hare/stdlib:$(SRCDIR)/hare/third-party
VERSION=$$(./scripts/version)

# for cross-compilation, modify the variables below
AARCH64_AS=gas
AARCH64_CC=cc
AARCH64_LD=cc

RISCV64_AS=gas
RISCV64_CC=cc
RISCV64_LD=cc

X86_64_AS=gas
X86_64_CC=cc
X86_64_LD=cc
