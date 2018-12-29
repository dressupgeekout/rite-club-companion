![](https://s3-us-west-2.amazonaws.com/noxalasdotnet/img/pyre.png)

# Rite Club Companion

The **Rite Club Companion** is a portable GUI application which helps out in
all sorts of interesting ways pertaining to the Rite Club's (unofficial)
[Pyre][] tournaments.

It runs on macOS, Windows and Linux, which are the three platforms on which
Pyre is officially supported.

The Rite Club Companion is distributed as a statically linked version of
[Tcl/Tk][] 8.6 (the "wish" program), a specially curated distribution of Tcl
libraries, and a launcher script.


## How to build

In theory, one could develop on the Rite Club Companion on any OS, but the
author uses Unix-like systems (macOS, Linux, NetBSD) and the provided Makefile
here assumes you are running on a Unix-like system.  Nevertheless, you can
still compile the Rite Club Companion for Windows, as long as you install the
[mingw-w64][] toolchain beforehand.

If you're building on a Mac, you can use Homebrew to install it:

```
$ brew install mingw-w64
```

If you're running Linux or some other system, your OS most likely already
distributes a `mingw-w64` package, try searching for it.

Now you can simply type:

```
$ make all
```

This will fetch the Tcl and Tk source code, compile it, and archive it with the
Rite Club Companion code.

You can build the Windows version if you have already installed `mingw-w64` like this:

```
$ make all PLATFORM=win
```

[![forthebadge](https://forthebadge.com/images/badges/built-by-codebabes.svg)](https://forthebadge.com)

[mingw-w64]: https://mingw-w64.org/doku.php
[Pyre]: https://www.supergiantgames.com/games/pyre/
[Tcl/Tk]: http://www.tcl.tk/
