# install locations
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man
SRCDIR = $(PREFIX)/src
STDLIB = $(SRCDIR)/hare/stdlib

# variables used during build
PLATFORM = darwin
ARCH = x86_64
HAREFLAGS =
HARECFLAGS =
QBEFLAGS =
ASFLAGS =
LDLINKFLAGS =

# commands used by the build script
HAREC = /usr/local/bin/harec
QBE = ../harec.git/rt/+darwin/qbe.sh
AS = ../harec.git/rt/+darwin/as.sh
CC = /usr/bin/cc
LD = ../harec.git/rt/+darwin/ld.sh
SCDOC = scdoc

# build locations
# HARECACHE = .cache
HARECACHE = /Volumes/hare-cache/.cache
BINOUT = .bin

# variables that will be embedded in the binary with -D definitions
HAREPATH = $(SRCDIR)/hare/stdlib:$(SRCDIR)/hare/third-party
VERSION=$$(./scripts/version)

AARCH64_AS=aarch64-as
AARCH64_CC=aarch64-cc
AARCH64_LD=aarch64-ld

RISCV64_AS=riscv64-as
RISCV64_CC=riscv64-cc
RISCV64_LD=riscv64-ld

X86_64_AS=$(AS)
X86_64_CC=$(CC)
X86_64_LD=$(LD)
