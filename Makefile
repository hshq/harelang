.POSIX:
.SUFFIXES:
include config.mk
TESTCACHE = $(HARECACHE)/+test
TESTHAREFLAGS = $(HAREFLAGS) -T
STDLIB = .

all:

.SUFFIXES: .ha .ssa .s .o .scd .1
.ssa.s:
	@printf 'QBE\t%s\n' "$@"
	@$(QBE) -o $@ $<

.s.o:
	@printf 'AS\t%s\n' "$@"
	@$(AS) -g -o $@ $<

.scd.1:
	@printf 'SCDOC\t%s\n' "$@"
	@$(SCDOC) < $< > $@

include stdlib.mk

hare_srcs = \
	./cmd/hare/main.ha \
	./cmd/hare/plan.ha \
	./cmd/hare/progress.ha \
	./cmd/hare/release.ha \
	./cmd/hare/schedule.ha \
	./cmd/hare/subcmds.ha \
	./cmd/hare/target.ha

harec_srcs = \
	./cmd/harec/main.ha \
	./cmd/harec/errors.ha

haredoc_srcs = \
	./cmd/haredoc/main.ha \
	./cmd/haredoc/errors.ha \
	./cmd/haredoc/env.ha \
	./cmd/haredoc/hare.ha \
	./cmd/haredoc/html.ha \
	./cmd/haredoc/sort.ha \
	./cmd/haredoc/resolver.ha

include targets.mk

$(HARECACHE)/hare.ssa: $(hare_srcs) $(stdlib_deps_any) $(stdlib_deps_$(PLATFORM)) scripts/version
	@printf 'HAREC\t%s\n' "$@"
	@HARECACHE=$(HARECACHE) $(HAREC) $(HAREFLAGS) \
		$(HARE_DEFINES) -o $@ $(hare_srcs)

$(TESTCACHE)/hare.ssa: $(hare_srcs) $(testlib_deps_any) $(testlib_deps_$(PLATFORM)) scripts/version
	@printf 'HAREC\t%s\n' "$@"
	@HARECACHE=$(TESTCACHE) $(HAREC) $(TESTHAREFLAGS) \
		$(HARE_DEFINES) -o $@ $(hare_srcs)

$(BINOUT)/hare: $(HARECACHE)/hare.o
	@mkdir -p $(BINOUT)
	@printf 'LD\t%s\n' "$@"
	@$(LD) --gc-sections -T $(rtscript) -o $@ \
		$(HARECACHE)/hare.o $(stdlib_deps_any) $(stdlib_deps_$(PLATFORM))

$(BINOUT)/hare-tests: $(TESTCACHE)/hare.o
	@mkdir -p $(BINOUT)
	@printf 'LD\t%s\n' "$@"
	@$(LD) -T $(rtscript) -o $@ \
		$(TESTCACHE)/hare.o $(testlib_deps_any) $(testlib_deps_$(PLATFORM))

$(BINOUT)/harec2: $(BINOUT)/hare $(harec_srcs)
	@mkdir -p $(BINOUT)
	@printf 'HARE\t%s\n' "$@"
	@env HAREPATH=. HAREC=$(HAREC) QBE=$(QBE) $(BINOUT)/hare build \
		$(HARE_DEFINES) -o $(BINOUT)/harec2 cmd/harec

# Prevent $(BINOUT)/hare from running builds in parallel, workaround for build
# driver bugs
PARALLEL_HACK=$(BINOUT)/harec2

$(BINOUT)/haredoc: $(BINOUT)/hare $(haredoc_srcs) $(PARALLEL_HACK)
	@mkdir -p $(BINOUT)
	@printf 'HARE\t%s\n' "$@"
	@env HAREPATH=. HAREC=$(HAREC) QBE=$(QBE) $(BINOUT)/hare build \
		$(HARE_DEFINES) -o $(BINOUT)/haredoc ./cmd/haredoc

docs/html: $(BINOUT)/haredoc scripts/gen-docs.sh
	BINOUT=$(BINOUT) $(SHELL) ./scripts/gen-docs.sh

docs/hare.1: docs/hare.scd
docs/haredoc.1: docs/haredoc.scd

docs: docs/hare.1 docs/haredoc.1

clean:
	rm -rf $(HARECACHE) $(BINOUT) docs/hare.1 docs/haredoc.1 docs/html

check: $(BINOUT)/hare-tests
	@$(BINOUT)/hare-tests

scripts/gen-docs.sh: scripts/gen-stdlib
scripts/gen-stdlib: scripts/gen-stdlib.sh

all: $(BINOUT)/hare $(BINOUT)/harec2 $(BINOUT)/haredoc

install: docs scripts/install-mods
	mkdir -p $(DESTDIR)$(BINDIR) $(DESTDIR)$(MANDIR)/man1 \
		$(DESTDIR)$(SRCDIR)/hare/stdlib
	install -m755 $(BINOUT)/hare $(DESTDIR)$(BINDIR)/hare
	install -m755 $(BINOUT)/haredoc $(DESTDIR)$(BINDIR)/haredoc
	install -m644 docs/hare.1 $(DESTDIR)$(MANDIR)/man1/hare.1
	install -m644 docs/haredoc.1 $(DESTDIR)$(MANDIR)/man1/haredoc.1
	./scripts/install-mods "$(DESTDIR)$(SRCDIR)/hare/stdlib"

uninstall:
	$(RM) $(DESTDIR)$(BINDIR)/hare
	$(RM) $(DESTDIR)$(BINDIR)/haredoc
	$(RM) $(DESTDIR)$(MANDIR)/man1/hare.1
	$(RM) $(DESTDIR)$(MANDIR)/man1/haredoc.1
	$(RM) -r $(DESTDIR)$(SRCDIR)/hare/stdlib

.PHONY: all clean check docs install uninstall $(BINOUT)/harec2 $(BINOUT)/haredoc
