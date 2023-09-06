.POSIX:
.SUFFIXES:
include config.mk
TESTCACHE = $(HARECACHE)/+test
TESTHAREFLAGS = $(HAREFLAGS) -T
STDLIB = .
stdlib_env = env
testlib_env = env

all:

.SUFFIXES: .ha .ssa .s .o .scd
.ssa.s:
	@printf 'QBE\t%s\n' "$@"
	@$(QBE) -o $@ $<

.s.o:
	@printf 'AS\t%s\n' "$@"
	@$(AS) -g -o $@ $<

.scd:
	@printf 'SCDOC\t%s\n' "$@"
	@$(SCDOC) < $< > $@


include stdlib.mk

hare_srcs = \
	./cmd/hare/arch.ha \
	./cmd/hare/build.ha \
	./cmd/hare/cache.ha \
	./cmd/hare/deps.ha \
	./cmd/hare/error.ha \
	./cmd/hare/main.ha \
	./cmd/hare/util.ha \
	./cmd/hare/version.ha

harec_srcs = \
	./cmd/harec/main.ha \
	./cmd/harec/errors.ha

haredoc_srcs = \
	./cmd/haredoc/main.ha \
	./cmd/haredoc/arch.ha \
	./cmd/haredoc/error.ha \
	./cmd/haredoc/util.ha \
	./cmd/haredoc/doc/color.ha \
	./cmd/haredoc/doc/hare.ha \
	./cmd/haredoc/doc/html.ha \
	./cmd/haredoc/doc/resolve.ha \
	./cmd/haredoc/doc/sort.ha \
	./cmd/haredoc/doc/tty.ha \
	./cmd/haredoc/doc/types.ha \
	./cmd/haredoc/doc/util.ha

include targets.mk

$(HARECACHE)/hare.ssa: $(hare_srcs) $(stdlib_deps_any) $(stdlib_deps_$(PLATFORM)) scripts/version
	@printf 'HAREC\t%s\n' "$@"
	@$(stdlib_env) $(HAREC) $(HAREFLAGS) \
		$(HARE_DEFINES) -o $@ $(hare_srcs)

$(TESTCACHE)/hare.ssa: $(hare_srcs) $(testlib_deps_any) $(testlib_deps_$(PLATFORM)) scripts/version
	@printf 'HAREC\t%s\n' "$@"
	@$(testlib_env) $(HAREC) $(TESTHAREFLAGS) \
		$(HARE_DEFINES) -o $@ $(hare_srcs)

$(BINOUT)/hare: $(HARECACHE)/hare.o
	@mkdir -p $(BINOUT)
	@printf 'LD\t%s\n' "$@"
	@$(LD) $(LDLINKFLAGS) --gc-sections -z noexecstack -T $(rtscript) -o $@ \
		$(HARECACHE)/hare.o $(stdlib_deps_any) $(stdlib_deps_$(PLATFORM))

$(BINOUT)/hare-tests: $(TESTCACHE)/hare.o
	@mkdir -p $(BINOUT)
	@printf 'LD\t%s\n' "$@"
	@$(LD) $(LDLINKFLAGS) -T $(rtscript) -o $@ \
		$(testlib_deps_any) $(testlib_deps_$(PLATFORM))

$(BINOUT)/harec2: $(BINOUT)/hare $(harec_srcs)
	@mkdir -p $(BINOUT)
	@printf 'HARE\t%s\n' "$@"
	@env HAREPATH=. HAREC=$(HAREC) QBE=$(QBE) $(BINOUT)/hare build \
		$(HARE_DEFINES) -o $(BINOUT)/harec2 cmd/harec

$(BINOUT)/haredoc: $(BINOUT)/hare $(haredoc_srcs)
	@mkdir -p $(BINOUT)
	@printf 'HARE\t%s\n' "$@"
	@env HAREPATH=. HAREC=$(HAREC) QBE=$(QBE) $(BINOUT)/hare build \
		$(HARE_DEFINES) -o $(BINOUT)/haredoc ./cmd/haredoc

docs/html: $(BINOUT)/haredoc scripts/gen-docs.sh
	BINOUT=$(BINOUT) $(SHELL) ./scripts/gen-docs.sh

docs/hare.1: docs/hare.1.scd
docs/haredoc.1: docs/haredoc.1.scd
docs/hare-doc.5: docs/hare-doc.5.scd

docs: docs/hare.1 docs/haredoc.1 docs/hare-doc.5

clean:
	rm -rf $(HARECACHE) $(BINOUT) docs/hare.1 docs/haredoc.1 docs/hare-doc.5 \
		docs/html

check: $(BINOUT)/hare-tests
	@$(BINOUT)/hare-tests

scripts/gen-docs.sh: scripts/gen-stdlib
scripts/gen-stdlib: scripts/gen-stdlib.sh

all: $(BINOUT)/hare $(BINOUT)/harec2 $(BINOUT)/haredoc docs

install: docs scripts/install-mods
	mkdir -p \
		$(DESTDIR)$(BINDIR) $(DESTDIR)$(MANDIR)/man1 \
		$(DESTDIR)$(BINDIR) $(DESTDIR)$(MANDIR)/man5 \
		$(DESTDIR)$(SRCDIR)/hare/stdlib
	install -m755 $(BINOUT)/hare $(DESTDIR)$(BINDIR)/hare
	install -m644 docs/hare.1 $(DESTDIR)$(MANDIR)/man1/hare.1
	install -m644 docs/haredoc.1 $(DESTDIR)$(MANDIR)/man1/haredoc.1
	install -m644 docs/hare-doc.5 $(DESTDIR)$(MANDIR)/man5/hare-doc.5
	./scripts/install-mods "$(DESTDIR)$(SRCDIR)/hare/stdlib"

uninstall:
	$(RM) $(DESTDIR)$(BINDIR)/hare
	$(RM) $(DESTDIR)$(MANDIR)/man1/hare.1
	$(RM) $(DESTDIR)$(MANDIR)/man1/haredoc.1
	$(RM) $(DESTDIR)$(MANDIR)/man5/hare-doc.5
	$(RM) -r $(DESTDIR)$(SRCDIR)/hare/stdlib

.PHONY: all clean check docs install uninstall
