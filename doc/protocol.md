# Protocol between Pyre and the Rite Club Companion

## Introduction

The Lua interpreter embedded into Pyre is significantly "locked down." Many
tables and functions that are ordinarily available to Lua scripts are simply
disabled in Pyre's case. Most notably missing are the `require()` function
and the `io` table, which prevents Pyre from opening arbitrary files and
other basic file-related tasks. Thus, we cannot modify Pyre to communicate
information relevant to the Rite Club by means of dumping data to a file.

Fortunately, there is at least one file descriptor which Pyre _can_ write
to: standard output. The Lua `print()` function is _not_ disabled. That is
the basis of how Pyre "talks" to the Rite Club Companion: it launches Pyre
on the user's behalf, ingesting Pyre's stdout stream, and reacts accordingly
when it encounters certain special messages. This document describes what
that communication looks like.


## Technical details

The Rite Club's goal is to enable the Rite Club functionality with as few
modifications to Pyre as possible. Therefore, little to no data processing
happens within Rite Club's version of Pyre. Instead, very simple
line-oriented messages are written to stdout whenever anything of interest
happens. It prevents the need for importing some data serialization format
into Pyre (e.g. JSON) and it fits in nicely with the other messages Pyre
already logs (the warnings and OpenGL spew are line-oriented).

Notifications are written to stdout in either of the two following formats:

    RITECLUB|<key>
    RITECLUB|<key>|<value>

The Rite Club Companion ignores all contents of the stream until it
encounters the `START` directive:

    RITECLUB|START

This indicates that a bunch of information pertaining to the current rite
will follow. The Rite Club Companion ingests all messages with the
`RITECLUB|` prefix until it counters the `STOP` directive:

    RITECLUB|STOP

At this stage, the Rite Club Companion formats all the information it
received between the "START" and "STOP" events and POSTs it to a database
over HTTP (the details of which are outside the scope of this document).
Then, the Companion awaits for another "START" event and the process begins
again.

Here are all of the directives which could occur between the "START" and
"STOP" events.

`RITECOMMENCED` -- This event is posted when players first gain control of
their exiles' movement. The Rite Club Companion takes the current time and
saves it.

`RITECONCLUDED` -- This event is posted immediately after one player's Pyre
runs out, i.e., the instant a winner could be declared. The Rite Club
Companion takes the difference between the current time and the time that
was saved with the `RITECOMMENCED` directive, yielding the duration of the
rite. The standard date and time functions are not available in Pyre's Lua
interpreter, therefore, the computation has to be made outside of Pyre.

`TEAM1ENDHP|value`, `TEAM2ENDHP|value` -- This event is posted when the rite
is ended. It reports how much "health" each player's Pyre had. Exactly one
of them will contain the value zero (otherwise, there's no clear winner).

    RITECLUB|TEAM1ENDHP|42
    RITECLUB|TEAM2ENDHP|0

`TEAM1EXILE|value`, `TEAM2EXILE|value` -- The Rite Club Companion appends
the given exile to a list of exiles.  This message is posted once per
exile. Therefore, this message is expected to be posted 6 times (3 for one
team and 3 for the other). The `value` is the numeric "character index,"
which is a constant mapping from integer to exile. 

    RITECLUB|TEAM1EXILE|1
    RITECLUB|TEAM1EXILE|6
    RITECLUB|TEAM1EXILE|20
    RITECLUB|TEAM2EXILE|7
    RITECLUB|TEAM2EXILE|11
    RITECLUB|TEAM2EXILE|2


`TEAM1STARTHP|value`, `TEAM2STARTHP|value` -- xxx

`TEAM1TRIUMVIRATE|value`, `TEAM2TRIUMVIRATE|value` -- xxx

`STAGE|value` -- xxx
