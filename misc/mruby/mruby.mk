WINDOWS?=	x86_64-w64-mingw32
WINDOWS_CC=	$(WINDOWS)-gcc
WINDOWS_AR=	$(WINDOWS)-ar

MRUBY_PREFIX?=	/usr/local

.PHONY: all
all: native windows

.PHONY: native
native: $(PROG)

.PHONY: windows
windows: $(PROG).exe

$(PROG): $(PROG).c
	$(CC) -I$(MRUBY_PREFIX)/include -L$(MRUBY_PREFIX)/build/host/lib -o $@ $< -lmruby

$(PROG).exe: $(PROG).c
	$(WINDOWS_CC) -I$(MRUBY_PREFIX)/include -L$(MRUBY_PREFIX)/build/mingw-w64/lib -o $@ $< -lmruby

.PHONY: clean
clean:
	rm -f $(PROG).exe $(PROG) *.o *.core
