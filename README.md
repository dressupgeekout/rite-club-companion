![](https://s3-us-west-2.amazonaws.com/noxalasdotnet/img/pyre.png)

# Rite Club Companion

The **Rite Club Companion** is a portable GUI application which helps out in
all sorts of interesting ways pertaining to the Rite Club's (unofficial)
[Pyre][] tournaments.

Its primary purpose is to modify Pyre in such a way that rites are
automatically recorded on the official [Rite Club Web][] server,
[noxalas.net](http://noxalas.net:9292) when rites are completed.

It runs on macOS, Windows and Linux, which are the three platforms on which
Pyre is officially supported.

The Rite Club Companion is distributed as a statically linked version of
[Tcl/Tk][] 8.6 (the "wish" program), a specially curated distribution of Tcl
libraries, and a launcher script.


## Quick development

If you already have Tk 8.6 installed, you can do quick development work on
your machine just by running `wish`:

```
$ wish8.6 ./script/main.tcl
```


## How to build a distribution

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

You might need to set several other variables. For example, your command
line will look like this if you're building on NetBSD:

```
$ PATH=/usr/pkg/cross/x86_64-w64-mingw32/bin:${PATH} gmake PLATFORM=win TAR=gtar all
```


## License

The Rite Club Companion app's source main source code is licensed under a
2-clause BSD-style license. See the LICENSE.md file for details.

[![forthebadge](https://forthebadge.com/images/badges/built-by-codebabes.svg)](https://forthebadge.com)

[mingw-w64]: https://mingw-w64.org/doku.php
[Pyre]: https://www.supergiantgames.com/games/pyre/
[Tcl/Tk]: http://www.tcl.tk/
[Rite Club Web]: http://github.com/dressupgeekout/rite-club-web
