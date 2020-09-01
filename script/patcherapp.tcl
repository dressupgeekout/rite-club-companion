#
# Rite Club Companion Patcher GUI
# ===============================
#
# Copyright (c) 2019, 2020 Charlotte Koch. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

package require platform

# === GLOBALS ===
set HERE [file normalize [file dirname $argv0]]
set IMG_DIR [file join ${HERE} "img"]
set PATCHDIR [file join ${HERE} "patch"]
set APP_NAME "Rite Club Patcher"

set NO_PATCH false

set __unset__ "(unset)"
set __unknown__ "(unknown)"
set PYRE_LOCATION ${__unset__}
set PYRE_VERSION ${__unknown__}

set fp [open "${HERE}/VERSION" r]
set VERSION [string trim [gets $fp]]
close $fp

image create photo pyre_logo -file "${IMG_DIR}/pyre.png"

set PATCHFILES_PLAIN [list \
  RiteClubScripts.lua        \
]

set PATCHFILES_DIFFS [list \
  MatchScripts.lua             \
  UIScripts.lua                \
]

# === UTILITY FUNCTIONS ===
proc note {msg} {
  global APP_NAME
  puts stderr "${APP_NAME}: ${msg}"
}

proc warning {msg} {
  note "WARNING: ${msg}"
}

proc warning_dialog {msg} {
  tk_messageBox -message $msg -type ok
}

# === MAIN WINDOW SETUP ===
wm title . ${APP_NAME}
wm iconphoto . -default pyre_logo
wm resizable . true true

ttk::label .title_label_img -image pyre_logo

proc destroy_about_window {} {
  wm forget .about_window
}

proc show_about_window {} {
  global APP_NAME
  global VERSION
  tk_messageBox -type ok -message "${APP_NAME} ${VERSION}\nDeveloped by dressupgeekout"
}

# Can return: "macOS", "Windows" or "Linux".
proc my_platform {} {
  set word [lindex [split [platform::generic] -] 0]

  if { $word == "macosx" } {
    return "macOS"
  } elseif { $word == "win32" } {
    return "Windows"
  } else {
    return "Linux"
  }
}

proc is_gog {} {
  global PYRE_LOCATION

  if {[my_platform] == "macOS"} {
    set alleged_gameinfo [file normalize [file join $PYRE_LOCATION "Contents" "Resources" "goggame-1408852789.info"]]
  } elseif {[my_platform] == "Windows"} {
    set allged_gameinfo [file normalize [file join $PYRE_LOCATION ".." "goggame-1408852789.info"]]
  } else {
    # XXX for now
    return false
  }

  return [file isfile $alleged_gameinfo]
}

# XXX I think this is totally outdated
proc get_pyre_version {} {
  global PYRE_LOCATION
  global PYRE_VERSION

  set gameinfo [file normalize [file join [file dirname $PYRE_LOCATION] .. gameinfo]]
  if [file isfile $gameinfo] {
    # The GOG 'gameinfo' file's first line should read "Pyre", and the
    # second line will be the version number.
    set fp [open $gameinfo r]
    set data [read $fp]
    close $fp
    set lines [split $data \n]
    set alleged_game [string trim [lindex $lines 0]]
    set alleged_version [string trim [lindex $lines 1]]
    if { $alleged_game != "Pyre" } {
      warning "this is not Pyre"
      # XXX exit
    }
    set PYRE_VERSION ${alleged_version}
  } else {
    # XXX should error!
    warning "can't determine Pyre version!"
  }

  set scripts_location [pyre_scripts_location]

  if {[file isdirectory $scripts_location]} {
    note "Pyre scripts location: $scripts_location"
  } else {
    warning "scripts location is not a directory: $scripts_location"
  }
}

# A user on macOS will provide the path to the .app bundle, but what we
# really want is the actual executable Mach-O binary.
proc pyre_real_location {} {
  global PYRE_LOCATION

  if {[my_platform] == "macOS"} {
    return [file join $PYRE_LOCATION "Contents" "MacOS" "Pyre"]
  } else {
    return $PYRE_LOCATION
  }
}

# Returns the path to Pyre's collection of Lua scripts, provided the user
# has pointed to the Pyre main executable.
proc pyre_scripts_location {} {
  # If Windows and GOG, then the Pyre exe is in a "x64" subdirectory, so we
  # need to travel back up.
  if {[my_platform] == "Windows"} {
    return [file join [file dirname [pyre_real_location]] ".." "Content" "Scripts"]
  } else {
    return [file join [file dirname [pyre_real_location]] "Content" "Scripts"]
  }
}

# Wrapper around GNU patch(1).
proc patch {origfile patchfile logchannel} {
  global HERE

  set patchutil [file normalize [file join $HERE ".." "bin" "gpatsch"]]
  if {[my_platform] == "Windows"} {set patchutil "${patchutil}.exe"}

  if {![file exists $patchutil]} {
    set patchutil "/usr/bin/patch"
  }

  if {![file exists $patchutil]} {
    warning_dialog "Cannot find patching tool!"
    return false
  }

  set stream [open "|\"${patchutil}\" -uN --binary \"${origfile}\" \"${patchfile}\""]
  while {[gets $stream line] >= 0} {
    puts $logchannel "(patch) $line"
  }
}

# Actually applies the patches to Pyre. Returns true if successful, or false if
# there was a problem.
proc patch_pyre {} {
  global NO_PATCH
  if $NO_PATCH { return true }

  global HERE
  global PYRE_LOCATION
  global PATCHDIR
  global PATCHFILES_PLAIN
  global PATCHFILES_DIFFS
  global __unset__

  # First a quick sanity check to make sure we actually have the patches we
  # want to apply.
  if {$PYRE_LOCATION == ${__unset__}} {
    warning_dialog "Sorry, please indicate where Pyre is located, first."
    return false
  }

  foreach {f} $PATCHFILES_PLAIN {
    if {![file exists [file join $PATCHDIR $f]]} {
      warning_dialog "Can't find patchfile $f!!"
      return false
    }
  }

  foreach {f} $PATCHFILES_DIFFS {
    if {![file exists [file join $PATCHDIR "patch-Scripts_${f}.diff"]]} {
      warning_dialog "Can't find patchfile $f!!"
      return false
    }

    # If the ".orig" version of the file exists, then assume we've already
    # patched everything. I think this is a relatively safe heuristic.
    if {[file exists [file join [pyre_scripts_location] "$f.orig"]]} {
      warning_dialog "Pyre seems to already be patched"
      return false
    }
  }

  set logfile [file tempfile logfile_path]
  note "Using logfile $logfile_path"

  # Back up all of the files which will be modified by the patches.
  foreach {f} $PATCHFILES_DIFFS {
    set msg "BACKUP $f"
    note $msg
    set origfile $f
    set backupfile "${f}.orig"
    file copy -force [file join [pyre_scripts_location] ${origfile}] [file join [pyre_scripts_location] ${backupfile}]
    puts $logfile $msg
  }

  # Simply copy over the "new" files.
  foreach {f} $PATCHFILES_PLAIN {
    set msg "COPY $f"
    note $msg
    file copy -force [file join $PATCHDIR $f] [pyre_scripts_location]
    puts $logfile $msg
  }
  
  # And then we'll actually apply the real patches.
  foreach {f} $PATCHFILES_DIFFS {
    set msg "PATCH $f"
    note $msg
    patch [file join [pyre_scripts_location] $f] [file join $PATCHDIR "patch-Scripts_${f}.diff"] $logfile
  }

  puts $logfile "Done"

  # We're done writing to the log, now we want its contents.
  close $logfile

  set logfile [open $logfile_path "r"]
  set log_contents [read $logfile]
  close $logfile

  warning_dialog $log_contents
  file delete -force $logfile_path

  return true
}

# XXX Ideally there'd be a way to determine to NOT do this in case it's not
# already patched.
proc unpatch_pyre {} {
  global PYRE_LOCATION
  global __unset__
  global PATCHFILES_PLAIN
  global PATCHFILES_DIFFS

  if {$PYRE_LOCATION == ${__unset__}} {
    warning_dialog "Sorry, please indicate where Pyre is located, first."
    return false
  }

  set logfile [file tempfile logfile_path]
  note "Using logfile $logfile_path"

  # The "new" files are simply deleted.
  foreach {f} $PATCHFILES_PLAIN {
    set candidate [file join [pyre_scripts_location] $f]
    if {[file isfile $candidate]} {
      set msg "REMOVE $f"
      note $msg
      file delete -force $candidate
      puts $logfile $msg
    }
  }

  # The proper diffs are reverted back to their original form. We clean up any
  # 'rejects' here, too.
  foreach {f} $PATCHFILES_DIFFS {
    set candidate [file join [pyre_scripts_location] "${f}.orig"]
    if {[file isfile $candidate]} {
      set msg "REVERT $f"
      note $msg
      file rename -force $candidate [file join [pyre_scripts_location] $f]
      puts $logfile $msg
    }

    set candidate [file join [pyre_scripts_location] "${f}.rej"]
    if {[file isfile $candidate]} {
      set msg "REMOVE $f.rej"
      note $msg
      file delete -force $candidate
      puts $logfile $msg
    }
  }

  puts $logfile "Done"

  # We're done writing to the log, now we want its contents.
  close $logfile

  set logfile [open $logfile_path "r"]
  set log_contents [read $logfile]
  close $logfile

  warning_dialog $log_contents
  file delete -force $logfile_path

  return true
}


# === WIDGETS ===
ttk::button .button1 -text "About..." -command show_about_window

# Setting the location of Pyre implies updating the Pyre launcher script, which
# will be used by the Companion app.
proc set_pyre_location {} {
  global HERE
  global PYRE_LOCATION

  set PYRE_LOCATION [tk_getOpenFile -parent .]

  if {[my_platform] == "Windows"} {
    set launcher_script [file join $HERE "launch_pyre.bat"]
  } else {
    set launcher_script [file join $HERE "launch_pyre.sh"]
  }

  set fp [open $launcher_script "w"]

  if {[my_platform] == "Windows"} {
    # Write a batch script
    puts $fp "REM AUTOMATICALLY GENERATED, DO NOT EDIT."
    puts $fp [string cat "cd \"" [file dirname $PYRE_LOCATION] "\""]
    puts $fp [file tail $PYRE_LOCATION]
  } else {
    # Write a shell script
    puts $fp "#!/bin/sh"
    puts $fp "# AUTOMATICALLY GENERATED, DO NOT EDIT."
    puts $fp [string cat "cd " [file dirname $PYRE_LOCATION]]
    puts $fp [file join "." [file tail $PYRE_LOCATION]]
  }

  close $fp

  # On Unix, the script needs to be explicitly executable.
  if {[my_platform] != "Windows"} {
    file attributes $launcher_script -permissions 0755
  }

  get_pyre_version
}

ttk::button .choose_pyre_button -text "Choose Pyre..." -command set_pyre_location

ttk::label .pyre_location_label -text "Pyre location:"
ttk::label .pyre_location -textvariable PYRE_LOCATION
ttk::label .pyre_version_label -text "Pyre version:"
ttk::label .pyre_version -textvariable PYRE_VERSION

ttk::button .do_patch_button -text "Patch it" -command patch_pyre
ttk::button .do_unpatch_button -text "Unpatch it" -command unpatch_pyre


# === WIDGET LAYOUT ===
grid .title_label_img -row 0 -column 0 -columnspan 2 -sticky news
grid .button1 -row 1 -column 0  -sticky news
grid .choose_pyre_button -row 2 -column 0 -sticky news

grid .pyre_location_label -row 3 -column 0 -sticky news
grid .pyre_location -row 3 -column 1 -sticky news
grid .pyre_version_label -row 4 -column 0 -sticky news
grid .pyre_version -row 4 -column 1 -sticky news

grid .do_patch_button -row 5 -column 0 -columnspan 2 -sticky news
grid .do_unpatch_button -row 6 -column 0 -columnspan 2 -sticky news


# === STARTUP COMMANDS ===
note "version ${VERSION}"

foreach {arg} $argv {
  if {$arg == "--no-patch"} { set NO_PATCH true }
}
