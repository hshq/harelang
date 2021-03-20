## Install configuration

# Where to install the stdlib tree
STDLIB=/usr/src/hare

# Default HAREPATH
HAREPATH=/usr/src/hare/stdlib:/usr/src/hare/third-party

## Build configuration

# Platform to build for
PLATFORM=+linux
ARCH=+x86_64

# External tools and flags
HAREC=harec
HAREFLAGS=
QBE=qbe
AS=as
LD=ld
AR=ar
SCDOC=scdoc

# Where to store build artifacts
HARECACHE=.cache
