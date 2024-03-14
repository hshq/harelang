# install locations
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man
SRCDIR = $(PREFIX)/src
STDLIB = $(SRCDIR)/hare/stdlib

# variables used during build
PLATFORM = darwin
ARCH = $(shell hare-arch.sh --arch)
HAREFLAGS =
HARECFLAGS =
QBEFLAGS =
ASFLAGS =
# LDLINKFLAGS = --gc-sections -z noexecstack
LDLINKFLAGS = -dead_strip
LDFLAGS = -dead_strip

# commands used by the build script
HAREC = harec
export QBE = hare-qbe.sh
AS = hare-as.sh
CC =  hare-cc.sh
LD =  hare-ld.sh
SCDOC = scdoc

# build locations
# HARECACHE = .cache
HARECACHE = /Volumes/hare-cache/hare.cache
BINOUT = .bin

# variables that will be embedded in the binary with -D definitions
HAREPATH = $(SRCDIR)/hare/stdlib:$(SRCDIR)/hare/third-party
VERSION=$$(./scripts/version)

# For cross-compilation, modify the variables below
AARCH64_AS=$(AS)
AARCH64_CC=$(CC)
AARCH64_LD=$(LD)

RISCV64_AS=as
RISCV64_CC=cc
RISCV64_LD=ld

X86_64_AS=$(AS)
X86_64_CC=$(CC)
X86_64_LD=$(LD)
