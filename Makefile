# This Makefile lets you build Rite Club's specific distribution of Tcl/Tk for
# Windows AND the build machine, provided that the build machine is Unix-based.

.DELETE_ON_ERROR:

VERSION?=	$(shell cat ./script/VERSION)
TCL_VERSION?=	8.6.9
TK_VERSION?=	8.6.9.1

URL_BASE?=		https://noxalasdotnet.s3-us-west-2.amazonaws.com/riteclubcompanion
TCL_SOURCE_URL?=	$(URL_BASE)/tcl$(TCL_VERSION)-src.tar.gz
TK_SOURCE_URL?=		$(URL_BASE)/tk$(TK_VERSION)-src.tar.gz
GNUWIN_PATCH_URL?=	$(URL_BASE)/patch-2.5.9-7-bin.zip
GNU_PATCH_SOURCE_URL?=	$(URL_BASE)/patch-2.7.6.tar.xz

LOVE_WINDOWS_URL?=	$(URL_BASE)/love-11.3-win64.zip
RUBY_WINDOWS_URL?=	$(URL_BASE)/rubyinstaller-2.6.6-1-x64.7z
FFMPEG_WINDOWS_URL?=	$(URL_BASE)/ffmpeg-4.3.1-win64-static.zip

distdir:=	dist

TCL_SOURCE_TARBALL=		$(distdir)/$(notdir $(TCL_SOURCE_URL))
TK_SOURCE_TARBALL=		$(distdir)/$(notdir $(TK_SOURCE_URL))
GNU_PATCH_SOURCE_TARBALL=	$(distdir)/$(notdir $(GNU_PATCH_SOURCE_URL))
GNUWIN_PATCH_ZIPBALL=		$(distdir)/$(notdir $(GNUWIN_PATCH_URL))

ifeq ($(PLATFORM),win)
LOVE_ZIPBALL=			$(distdir)/$(notdir $(LOVE_WINDOWS_URL))
RUBY_ZIPBALL=			$(distdir)/$(notdir $(RUBY_WINDOWS_URL))
FFMPEG_ZIPBALL=			$(distdir)/$(notdir $(FFMPEG_WINDOWS_URL))
endif

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
gpatch_bin_basename=	gpatsch

ifeq ($(PLATFORM),macosx)
GNU_PATCH_DIST=	$(GNU_PATCH_SOURCE_TARBALL)
GPATCH_BIN=	$(gpatch_bin_basename)
# XXX WISH_BIN=
archive=	$(archive_basename)-macosx.tar.gz
launch_script=	rite_club_patcher
endif
ifeq ($(PLATFORM),unix)
GNU_PATCH_DIST=	$(GNU_PATCH_SOURCE_TARBALL)
GPATCH_BIN=	$(gpatch_bin_basename)
# XXX WISH_BIN=
archive=	$(archive_basename)-linux.tar.gz
launch_script=	rite_club_patcher
endif
ifeq ($(PLATFORM),win)
GNU_PATCH_DIST=	$(GNUWIN_PATCH_ZIPBALL)
GPATCH_BIN=	$(gpatch_bin_basename).exe
WISH_BIN=	wish86s.exe
archive=	$(archive_basename)-windows.zip
launch_script=	"Rite Club Patcher.bat"
endif

workdir:=		work.$(PLATFORM)
tcl_workdir:=		$(workdir)/tcl$(TCL_VERSION)/$(PLATFORM)
# XXX bleh vv
tk_workdir:=		$(workdir)/tk$(TCL_VERSION)/$(PLATFORM)
gpatch_workdir:=	$(workdir)/$(subst .tar.xz,,$(notdir $(GNU_PATCH_SOURCE_URL)))
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

ifneq ($(PLATFORM),win)
gpatch_configure_flags=		# defined
gpatch_configure_flags+=	--disable-shared
endif

tcl_done=	.tcl-$(PLATFORM)-done
tk_done=	.tk-$(PLATFORM)-done
gpatch_done=	.gpatch-$(PLATFORM)-done

######### ######### ######### #########

.PHONY: help
help:
	@echo Available targets:
	@echo - all
	@echo - fetch
	@echo - tcl PLATFORM=macosx\|unix\|win
	@echo - tk PLATFORM=macosx\|unix\|win
	@echo - gpatch PLATFORM=macosx\|unix\|win
	@echo - archive PLATFORM=macosx\|unix\|win
	@echo - clean PLATFORM=macosx\|unix\|win

.PHONY: all
all: $(archive)

.PHONY: fetch
fetch:				\
	$(TCL_SOURCE_TARBALL)	\
	$(TK_SOURCE_TARBALL)	\
	$(GNU_PATCH_DIST)	\
	$(LOVE_ZIPBALL)		\
	$(RUBY_ZIPBALL)		\
	$(FFMPEG_ZIPBALL)

$(TCL_SOURCE_TARBALL): | $(distdir)
	curl -L $(TCL_SOURCE_URL) > $@
	cd $(distdir) && shasum -a256 -c tcl.shasum
	@touch $@

$(TK_SOURCE_TARBALL): | $(distdir)
	curl -L $(TK_SOURCE_URL) > $@
	cd $(distdir) && shasum -a256 -c tk.shasum
	@touch $@

$(GNU_PATCH_SOURCE_TARBALL): | $(distdir)
	curl -L $(GNU_PATCH_SOURCE_URL) > $@
	cd $(distdir) && shasum -a256 -c gpatch.shasum
	@touch $@

$(GNUWIN_PATCH_ZIPBALL): | $(distdir)
	curl -L $(GNUWIN_PATCH_URL) > $@
	cd $(distdir) && shasum -a256 -c gnuwinpatch.shasum
	@touch $@

$(LOVE_ZIPBALL): | $(distdir)
	curl -L $(LOVE_WINDOWS_URL) > $@
	cd $(distdir) && shasum -a256 -c love-win64.shasum
	@touch $@

$(RUBY_ZIPBALL): | $(distdir)
	curl -L $(RUBY_WINDOWS_URL) > $@
	cd $(distdir) && shasum -a256 -c ruby-win64.shasum
	@touch $@

$(FFMPEG_ZIPBALL): | $(distdir)
	curl -L $(FFMPEG_WINDOWS_URL) > $@
	cd $(distdir) && shasum -a256 -c ffmpeg-win64.shasum
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

.PHONY: gpatch
gpatch: $(gpatch_done)

# Even though mingw-w64 is available to us, we're not going to cross-compile
# GNU patch(1) (there are build errors I'm not sure how to fix, at the
# absolute least). So if we're trying to make the Windows distribution, then
# simply copy the precompiled patch.exe... and then rename it to something
# silly because of a Windows 7+ "security feature" where executables with
# the word "patch" in their names require elevated privileges.
$(gpatch_done): $(GNU_PATCH_DIST) | $(workdir)
ifeq ($(PLATFORM),win)
	dir=$$(mktemp -d /tmp/gpatch.XXXXXX);				\
		(cd $${dir} && unzip $(CURDIR)/$<);			\
		cp $${dir}/bin/patch.exe $(workdir)/$(GPATCH_BIN);	\
		rm -rf $${dir};
else
	$(TAR) -x -f $< -C $(workdir)
	cd $(gpatch_workdir) && ./configure $(gpatch_configure_flags)
	$(MAKE) -C $(gpatch_workdir)
endif
	@touch $@

.PHONY: archive
archive: $(archive)

$(archive): $(tk_done) $(gpatch_done) $(shell find script -type f) | $(archive_workdir)
	mkdir -p $(archive_workdir)/bin
	cp -r $(CURDIR)/script $(archive_workdir)
	cp -r $(tcl_workdir)/../library $(archive_workdir)
	cp -r $(tk_workdir)/../library $(archive_workdir)/library/tk8.6
ifeq ($(PLATFORM),win)
	cp $(tk_workdir)/$(WISH_BIN) $(archive_workdir)/bin
	cp $(workdir)/$(GPATCH_BIN) $(archive_workdir)/bin
	echo 'bin\\$(WISH_BIN) script\\patcherapp.tcl' > $(archive_workdir)/$(launch_script)
	cd $(dir $(archive_workdir)) && zip -r $@ $(notdir $(archive_workdir))
	mv $(dir $(archive_workdir))/$@ $@
else
	echo '#!/bin/sh' > $(archive_workdir)/$(launch_script)
	echo 'set -ex' >> $(archive_workdir)/$(launch_script)
	echo './bin/$(WISH_BIN) ./script/patcherapp.tcl' >> $(archive_workdir)/$(launch_script)
	cp $(gpatch_workdir)/src/patch $(archive_workdir)/bin/$(GPATCH_BIN)
	chmod +x $(archive_workdir)/$(launch_script)
	tar -c -f $@ -C $(dir $(archive_workdir)) $(notdir $(archive_workdir))
endif

.PHONY: clean
clean:
	rm -rf $(workdir) $(tcl_done) $(tk_done) $(gpatch_done)

######### ######### ######### #########

$(distdir):
	mkdir -p $@
$(workdir):
	mkdir -p $@
$(archive_workdir):
	mkdir -p $@
