# This Makefile lets you build Rite Club's specific distribution of Tcl/Tk for
# Windows AND the build machine, provided that the build machine is Unix-based.

.DELETE_ON_ERROR:

VERSION?=	$(shell cat ./script/VERSION)
TCL_VERSION?=	8.6.9
TK_VERSION?=	8.6.9.1

TCL_SOURCE_URL?=	https://prdownloads.sourceforge.net/tcl/tcl$(TCL_VERSION)-src.tar.gz
TK_SOURCE_URL?=		https://prdownloads.sourceforge.net/tcl/tk$(TK_VERSION)-src.tar.gz

distdir:=	dist

TCL_SOURCE_TARBALL=	$(distdir)/$(notdir $(TCL_SOURCE_URL))
TK_SOURCE_TARBALL=	$(distdir)/$(notdir $(TK_SOURCE_URL))

MINGW_TRIPLE?=	x86_64-w64-mingw32

# Turns out both the Tcl and Tk tarballs require GNU tar to extract. You
# might need add "TAR=gtar" to your command line.
TAR?=	tar

ifndef PLATFORM
ifeq ($(shell uname -s),Darwin)
PLATFORM?=	macosx
else
PLATFORM?=	unix
endif # ifeq uname Darwin
endif # ifndef PLATFORM

archive_basename=	rite_club_companion-$(VERSION)

ifeq ($(PLATFORM),macosx)
# XXX WISH_BIN=
archive=	$(archive_basename)-macosx.tar.gz
launch_script=	rite_club_companion
endif
ifeq ($(PLATFORM),unix)
# XXX WISH_BIN=
archive=	$(archive_basename)-linux.tar.gz
launch_script=	rite_club_companion
endif
ifeq ($(PLATFORM),win)
WISH_BIN=	wish86s.exe
archive=	$(archive_basename)-windows.zip
launch_script=	"Rite Club Companion.bat"
endif

workdir:=		work.$(PLATFORM)
tcl_workdir:=		$(workdir)/tcl$(TCL_VERSION)/$(PLATFORM)
# XXX bleh vv
tk_workdir:=		$(workdir)/tk$(TCL_VERSION)/$(PLATFORM)
archive_workdir:=	$(workdir)/$(archive_basename)

tcl_configure_flags=	# defined
tcl_configure_flags+=	--disable-shared
tcl_configure_flags+=	--without-tzdata
ifeq ($(PLATFORM),win)
tcl_configure_flags+=	--host=$(MINGW_TRIPLE)
endif

tk_configure_flags=	# defined
tk_configure_flags+=	--disable-shared
tk_configure_flags+=	--with-tcl=$(CURDIR)/$(tcl_workdir)
ifeq ($(PLATFORM),macosx)
tk_configure_flags+=	--enable-aqua
endif
ifeq ($(PLATFORM),win)
tk_configure_flags+=	--host=$(MINGW_TRIPLE)
endif

tcl_done=	.tcl-$(PLATFORM)-done
tk_done=	.tk-$(PLATFORM)-done

######### ######### ######### #########

.PHONY: help
help:
	@echo Available targets:
	@echo - all
	@echo - fetch
	@echo - tcl PLATFORM=macosx\|unix\|windows
	@echo - tk PLATFORM=macosx\|unix\|windows
	@echo - archive PLATFORM=macosx\|unix\|windows
	@echo - clean PLATFORM=macosx\|unix\|windows

.PHONY: all
all: $(archive)

.PHONY: fetch
fetch: $(TCL_SOURCE_TARBALL) $(TK_SOURCE_TARBALL)

$(TCL_SOURCE_TARBALL): | $(distdir)
	curl -L $(TCL_SOURCE_URL) > $@
	cd $(distdir) && shasum -a256 -c tcl.shasum
	@touch $@

$(TK_SOURCE_TARBALL): | $(distdir)
	curl -L $(TK_SOURCE_URL) > $@
	cd $(distdir) && shasum -a256 -c tk.shasum
	@touch $@

.PHONY: tcl
tcl: $(tcl_done)

$(tcl_done): $(TCL_SOURCE_TARBALL) | $(workdir)
	$(TAR) -x -f $< -C $(workdir)
	cd $(tcl_workdir) && ./configure $(tcl_configure_flags)
	$(MAKE) -C $(tcl_workdir)
	@touch $@

.PHONY: tk
tk: $(tk_done)

$(tk_done): $(TK_SOURCE_TARBALL) $(tcl_done) | $(workdir)
	$(TAR) -x -f $< -C $(workdir)
	cd $(tk_workdir) && ./configure $(tk_configure_flags)
	$(MAKE) -C $(tk_workdir)
	@touch $@

.PHONY: archive
archive: $(archive)

$(archive): $(tk_done) $(shell find script -type f) | $(archive_workdir)
	mkdir -p $(archive_workdir)/bin
	cp -r $(CURDIR)/script $(archive_workdir)
	cp -r $(tcl_workdir)/../library $(archive_workdir)
	cp -r $(tk_workdir)/../library $(archive_workdir)/library/tk8.6
ifeq ($(PLATFORM),win)
	cp $(tk_workdir)/$(WISH_BIN) $(archive_workdir)/bin
	echo 'bin\\$(WISH_BIN) script\\main.tcl' > $(archive_workdir)/$(launch_script)
	cd $(dir $(archive_workdir)) && zip -r $@ $(notdir $(archive_workdir))
	mv $(dir $(archive_workdir))/$@ $@
else
	echo '#!/bin/sh' > $(archive_workdir)/$(launch_script)
	echo 'set -ex' >> $(archive_workdir)/$(launch_script)
	echo './bin/$(WISH_BIN) ./script/main.tcl' >> $(archive_workdir)/$(launch_script)
	chmod +x $(archive_workdir)/$(launch_script)
	tar -c -f $@ -C $(dir $(archive_workdir)) $(notdir $(archive_workdir))
endif

.PHONY: clean
clean:
	rm -rf $(workdir) $(tcl_done) $(tk_done)

######### ######### ######### #########

$(distdir):
	mkdir -p $@
$(workdir):
	mkdir -p $@
$(archive_workdir):
	mkdir -p $@
