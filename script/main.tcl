#
# Rite Club Companion main GUI
#

package require http
package require platform

# === GLOBALS ===
set HERE [file normalize [file dirname $argv0]]
set IMG_DIR [file join ${HERE} "img"]
set PATCHDIR [file join ${HERE} "patch"]
set APP_NAME "Rite Club Companion"

if {[lindex $argv 0] == "--debug"} {
  set DATABASE_SERVER "http://localhost:9292"
} else {
  set DATABASE_SERVER "http://noxalas.net:9292"
}

set __unset__ "(unset)"
set __unknown__ "(unknown)"
set PYRE_LOCATION ${__unset__}
set PYRE_VERSION ${__unknown__}

set ALL_READERS ""
set ALL_READER_NAMES [list]
set RITE_LABEL ""

set fp [open "${HERE}/VERSION" r]
set VERSION [string trim [gets $fp]]
close $fp

source [file join ${HERE}/ton.tcl]

image create photo pyre_logo -file "${IMG_DIR}/pyre.png"

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
#wm geometry . "=800x600"
wm resizable . true true

ttk::label .title_label_img -image pyre_logo

proc destroy_about_window {} {
  wm forget .about_window
}

# XXX Can't show this window twice! 
proc show_about_window {} {
  global APP_NAME
  global VERSION
  tk_messageBox -type ok -message "${APP_NAME} ${VERSION}\nDeveloped by Charlotte Koch"
}

# Can return: "macOS", "Windows" or "Linux".
#
# XXX verify what [platform::generic] returns on Windows.
proc my_platform {} {
  set word [lindex [split [platform::generic] -] 0]

  if { $word == "macosx"} {
    return "macOS"
  } elseif { $word == "win" } {
    return "Windows"
  } else {
    return "Linux"
  }
}

# XXX This currently assumes the game comes from GOG.
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
      warning "this is not pyre"
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

  if [pyre_is_patched] {
    note "Pyre is appropriately patched"
  } else {
    note "Pyre is NOT appropriately patched"
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
  return [file join [file dirname [pyre_real_location]] "Content" "Scripts"]
}

# XXX Should make these determinations with SHA sums or something
proc pyre_is_patched {} {
  if {![file isfile [file join [pyre_scripts_location] "RiteClubScripts.lua"]]} {
    return false
  }

  # XXX I want to test the patching-code for now
  return false
}

# Wrapper around GNU patch(1).
proc patch {origfile patchfile} {
 # XXX set patchutil [file normalize [file join $HERE ".." ".." "bin" "patch"]]
 set patchutil /tmp/patch-2.7.6/src/patch

 set stream [open "|${patchutil} -uN ${origfile} ${patchfile}"]
 while {[gets $stream line] >= 0} {
   note "(patch) $line"
 }
}

# Actually applies the patches to Pyre. Returns true if successful, or false if
# there was a problem.
proc patch_pyre {} {
  global HERE
  global PATCHDIR

  set plain_copies [list \
    RiteClubScripts.lua  \
  ]

  set diff_basenames [list \
    MatchScripts           \
    UIScripts
  ]

  # First a quick sanity check to make sure we actually have the patches we
  # want to apply.
  foreach {f} $plain_copies {
    if {![file exists [file join $PATCHDIR $f]]} {
      warning_dialog "Can't find patchfile $f!!"
      return false
    }
  }

  foreach {f} $diff_basenames {
    if {![file exists [file join $PATCHDIR "patch-Scripts_${f}.lua.diff"]]} {
      warning_dialog "Can't find patchfile $f!!"
      return false
    }
  }

  # OK, let's simply copy over the "new" files.
  foreach {f} $plain_copies {
    note "COPY $f -> [pyre_scripts_location]"
    file copy -force [file join $PATCHDIR $f] [pyre_scripts_location]
  }

  # And then we'll actually apply the patches.
  foreach {f} $diff_basenames {
    patch [file join [pyre_scripts_location] "${f}.lua"] [file join $PATCHDIR "patch-Scripts_${f}.lua.diff"]
  }

  return true
}

# XXX require a proper JSON generator
proc generate_json_payload {team_a team_b rite} {
  global RITE_LABEL

  set fp [open "/tmp/payload" w+]

  puts $fp "{"
  puts $fp "  \"player_a\": {"
  puts $fp "    \"id\": [reader_id_from_username [.reader_a_selection get]],"
  puts $fp "    \"triumvirate\": [dict get $team_a triumvirate],"
  puts $fp "    \"input_method\": 1,"
  puts $fp "    \"pyre_start_health\": [dict get $team_a starthp],"
  puts $fp "    \"pyre_end_health\": [dict get $team_a endhp],"
  puts $fp "    \"host\": true,"
  puts $fp "    \"exiles\": \["
  puts $fp "      {"
  puts $fp "        \"character_index\": [lindex [dict get $team_a exiles] 0]"
  puts $fp "      },"
  puts $fp "      {"
  puts $fp "        \"character_index\": [lindex [dict get $team_a exiles] 1]"
  puts $fp "      },"
  puts $fp "      {"
  puts $fp "        \"character_index\": [lindex [dict get $team_a exiles] 2]"
  puts $fp "      }"
  puts $fp "    ]"
  puts $fp "  },"
  puts $fp "  \"player_b\": {"
  puts $fp "    \"id\": [reader_id_from_username [.reader_b_selection get]],"
  puts $fp "    \"triumvirate\": [dict get $team_b triumvirate],"
  puts $fp "    \"input_method\": 2,"
  puts $fp "    \"pyre_start_health\": [dict get $team_b starthp],"
  puts $fp "    \"pyre_end_health\": [dict get $team_b endhp],"
  puts $fp "    \"host\": false,"
  puts $fp "    \"exiles\": \["
  puts $fp "      {"
  puts $fp "        \"character_index\": [lindex [dict get $team_b exiles] 0]"
  puts $fp "      },"
  puts $fp "      {"
  puts $fp "        \"character_index\": [lindex [dict get $team_b exiles] 1]"
  puts $fp "      },"
  puts $fp "      {"
  puts $fp "        \"character_index\": [lindex [dict get $team_b exiles] 2]"
  puts $fp "      }"
  puts $fp "    ]"
  puts $fp "  },"
  puts $fp "  \"rite\": {"
  puts $fp "    \"label\": \"${RITE_LABEL}\","
  puts $fp "    \"stage\": [dict get $rite stage],"
  puts $fp "    \"masteries_allowed\": 4,"
  puts $fp "    \"duration\": [dict get $rite duration],"
  puts $fp "    \"talismans_enabled\": [dict get $rite talismans_enabled]"
  puts $fp "  }"
  puts $fp "}"

  close $fp

  set fp [open "/tmp/payload" r]
  return $fp
}

# This performs the transformation: "TeamName02" -> 2
proc team_key_to_index {key} {
  set index [regsub {TeamName0?} $key ""]
  note "TRANSFORM ${key} -> ${index}"
  return $index
}

# This performs the transformation: "MatchSiteE" -> 5
proc match_site_key_to_index {key} {
  set alphabet [list A B C D E F G H I J]
  set letter [regsub {MatchSite} $key ""]
  # +1 to ensure A=>1, not A=>0
  set index [expr [lsearch $alphabet $letter] + 1]
  note "TRANSFORM ${key} -> ${letter} -> ${index}"
  return $index
}

proc handle_pyre_output {stream} {
  global HERE
  global DATABASE_SERVER

  while {[gets $stream line] >= 0} {
    if [regexp {^RITECLUB} ${line}] {
      set tokens [split $line "|"]
      set beacon [lindex $tokens 0]
      set directive [lindex $tokens 1]
      set value [lindex $tokens 2]

      if { $directive == "START" } {
        set team_a [dict create exiles [list]]
        set team_b [dict create exiles [list]]
        set rite [dict create stage ""]
      }

      # Got all rite data, upload it!
      if { $directive == "STOP" } {
        # There isn't a readymade 'stringio' class, so its just easier to read/write
        # to/from a file >:|
        #
        # XXX This works, just needs to be prettified
        set fp [generate_json_payload ${team_a} ${team_b} ${rite}]
        set token [::http::geturl "${DATABASE_SERVER}/api/v1/rites" -method POST -type application/json -querychannel $fp]
        close $fp
        ::http::cleanup $token

        unset team_a
        unset team_b
        unset rite
      }

      if { $directive == "RITECOMMENCED" } { dict set rite commence_time [clock seconds] }
      if { $directive == "RITECONCLUDED" } { dict set rite duration [expr [clock seconds] - [dict get $rite commence_time]] }
      if { $directive == "TEAM1ENDHP" } { dict set team_a endhp $value }
      if { $directive == "TEAM2ENDHP" } { dict set team_b endhp $value }
      if { $directive == "TEAM1EXILE" } { dict lappend team_a exiles $value }
      if { $directive == "TEAM2EXILE" } { dict lappend team_b exiles $value }
      if { $directive == "TEAM1STARTHP" } { dict set team_a starthp $value }
      if { $directive == "TEAM2STARTHP" } { dict set team_b starthp $value }
      if { $directive == "TEAM1TRIUMVIRATE" } { dict set team_a triumvirate [team_key_to_index $value] }
      if { $directive == "TEAM2TRIUMVIRATE" } { dict set team_b triumvirate [team_key_to_index $value] }
      if { $directive == "TALISMANS" } { dict set rite talismans_enabled $value }
      if { $directive == "STAGE" } { dict set rite stage [match_site_key_to_index $value] }
    }
  }
}

proc pyre_preflight_checks {} {
  global PYRE_LOCATION
  global __unset__

  set reader_a [.reader_a_selection get]
  set reader_b [.reader_b_selection get]

  set prefix "Can't launch Pyre."

  if {$PYRE_LOCATION == ${__unset__}} {
    warning_dialog "${prefix} You haven't noted where Pyre is located!"
    return false
  }

  if {$reader_a == ""} {
    warning_dialog "${prefix} Reader A is not selected"
    return false
  }

  if {$reader_b == ""} {
    warning_dialog "${prefix} Reader B is not selected"
    return false
  }

  if {$reader_a == $reader_b} {
    warning_dialog "${prefix} ${reader_a} cannot compete against themselves!"
    return false
  }

  return true
}

proc launch_pyre {} {
  global PYRE_LOCATION

  if {![pyre_preflight_checks]} {
    return false
  }

  if {![pyre_is_patched]} {
    if {![patch_pyre]} {
      warning_dialog "Cannot launch Pyre!"
      return false
    }
  }

  set real_location [pyre_real_location]
  note "launching Pyre at: ${real_location}"
  set stream [open "|\"${real_location}\""]
  handle_pyre_output $stream
  note "Pyre quit"
}

proc ping_database_server {} {
  global DATABASE_SERVER

  set token [::http::geturl ${DATABASE_SERVER} -validate true]
  set status_code [::http::ncode ${token}]
  ::http::cleanup ${token}
  if { ${status_code} == 200 } {
    note "ping ${DATABASE_SERVER} OK"
  } else  {
    # XXX is an error
    warning_dialog "Couldn't ping ${DATABASE_SERVER}"
  }
}

proc fetch_readers {} {
  global DATABASE_SERVER
  global ALL_READERS
  global ALL_READER_NAMES

  if {[llength $ALL_READER_NAMES] > 0} {
    return $ALL_READER_NAMES
  }

  set token [::http::geturl ${DATABASE_SERVER}/api/v1/usernames -method GET]
  set status_code [::http::ncode $token]
  set result [list]

  if { $status_code == 200 } {
    set res_body [::http::data $token]
    note "Got usernames: ${res_body}"
    set ALL_READERS [namespace eval ton::2list [ton::json2ton $res_body]]
  } else {
    warning_dialog "Couldn't get usernames!"
    ::http::cleanup $token
    return $result
  }

  ::http::cleanup $token

  for {set i 0} {$i < [expr [llength $ALL_READERS]-1]} {incr i} {
    lappend result [ton::2list::get $ALL_READERS $i username]
  }

  set ALL_READER_NAMES $result
  return $ALL_READER_NAMES
}

proc reader_id_from_username {username} {
  global ALL_READERS

  for {set i 0} {$i < [expr [llength $ALL_READERS]-1]} {incr i} {
    set user [ton::2list::get $ALL_READERS $i]
    if {[ton::2list::get $user username] == $username} {
      return [ton::2list::get $user id]
    }
  }
}

# === MENU BAR ===
menu .menubar -tearoff false
menu .menubar.file -tearoff false
menu .menubar.file.about -tearoff false
menu .menubar.file.quit -tearoff false
menu .menubar.xxx -tearoff false
.menubar add cascade -label "File" -menu .menubar.file
.menubar.file add cascade -label "About..." -menu .menubar.file.about
.menubar.file add cascade -label "Quit" -menu .menubar.file.quit
.menubar add cascade -label "Blah" -menu .menubar.xxx
. configure -menu .menubar


# === XXX ===
ttk::button .button1 -text "About..." -command show_about_window

proc set_pyre_location {} {
  global PYRE_LOCATION
  set PYRE_LOCATION [tk_getOpenFile -parent .]
  get_pyre_version
}

ttk::button .choose_pyre_button -text "Choose Pyre..." -command set_pyre_location

ttk::label .pyre_location_label -text "Pyre location:"
ttk::label .pyre_location -textvariable PYRE_LOCATION
ttk::label .pyre_version_label -text "Pyre version:"
ttk::label .pyre_version -textvariable PYRE_VERSION

ttk::label .reader_a_label -text "Reader A:"
ttk::combobox .reader_a_selection -justify left -state readonly -postcommand {
  .reader_a_selection configure -values [fetch_readers]
}

ttk::label .reader_b_label -text "Reader B:"
ttk::combobox .reader_b_selection -justify left -state readonly -postcommand {
  .reader_b_selection configure -values [fetch_readers]
}

ttk::label .rite_label_label -text "Label:"
ttk::entry .rite_label_input -state normal -justify left -textvariable RITE_LABEL

ttk::button .launch_pyre_button -text "Launch!" -command launch_pyre


# === WIDGET LAYOUT ===
grid .title_label_img -row 0 -column 0 -columnspan 2 -sticky news
grid .button1 -row 1 -column 0  -sticky news
grid .choose_pyre_button -row 2 -column 0 -sticky news

grid .pyre_location_label -row 3 -column 0 -sticky news
grid .pyre_location -row 3 -column 1 -sticky news
grid .pyre_version_label -row 4 -column 0 -sticky news
grid .pyre_version -row 4 -column 1 -sticky news

grid .reader_a_label -row 5 -column 0 -sticky news
grid .reader_a_selection -row 5 -column 1 -sticky news
grid .reader_b_label -row 6 -column 0 -sticky news
grid .reader_b_selection -row 6 -column 1 -sticky news

grid .rite_label_label -row 7 -column 0 -sticky news
grid .rite_label_input -row 7 -column 1 -sticky news

grid .launch_pyre_button -row 8 -column 0 -columnspan 2 -sticky news


# === STARTUP COMMANDS ===
note "version ${VERSION}"

catch {
  ping_database_server
}

catch {
  fetch_readers
}
