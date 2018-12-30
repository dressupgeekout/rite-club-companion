#
# Rite Club Companion main GUI
#

package require http
package require platform

# === GLOBALS ===
set HERE [file normalize [file dirname $argv0]]
set IMG_DIR [file join ${HERE} "img"]
set APP_NAME "Rite Club Companion"

set PYRE_LOCATION "(unset)"
set PYRE_VERSION "(unknown version)"

set fp [open "${HERE}/VERSION"]
set VERSION [string trim [gets $fp]]
close $fp

image create photo pyre_logo -file "${IMG_DIR}/pyre.png"

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

  if [info exists .about_window] {} else { toplevel .about_window }
  wm title .about_window "About ${APP_NAME}"
  wm geometry .about_window "=300x150"

  ttk::label .about_window.version_text -text "${APP_NAME} ${VERSION}\nDeveloped by Charlotte Koch"
  ttk::button .about_window.ok_button -text "OK" -command destroy_about_window

  pack .about_window.version_text
  pack .about_window.ok_button
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
      puts "this is not pyre"
      # XXX exit
    }
    set PYRE_VERSION ${alleged_version}
  } else {
    # XXX should error!
    puts "invalid!!"
  }
}

proc ping_database_server {} {
  set token [::http::geturl "http://noxalas.net" -validate true]
  set status_code [::http::ncode ${token}]
  ::http::cleanup ${token}
  if { ${status_code} == 200 } {
    puts "PING OK"
  } else  {
    # XXX is an error
    puts "COULDN'T PING!"
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
ttk::button .button1 -text "click me" -command show_about_window

proc set_pyre_location {} {
  global PYRE_LOCATION

  if [string match "macosx" [platform::generic]] {
    set PYRE_LOCATION [::tk::mac::OpenApplication]
  } else {
    set PYRE_LOCATION [tk_getOpenFile -parent .]
  }

  get_pyre_version
}

ttk::button .choose_pyre_button -text "Choose Pyre..." -command set_pyre_location

ttk::label .pyre_location_label -text "Pyre location:"
ttk::label .pyre_location -textvariable PYRE_LOCATION
ttk::label .pyre_version_label -text "Pyre version:"
ttk::label .pyre_version -textvariable PYRE_VERSION


# === WIDGET LAYOUT ===
grid .title_label_img -row 0 -column 0 -columnspan 2 -sticky news
grid .button1 -row 1 -column 0  -sticky news
grid .choose_pyre_button -row 2 -column 0 -sticky news
grid .pyre_location_label -row 3 -column 0 -sticky news
grid .pyre_location -row 3 -column 1 -sticky news
grid .pyre_version_label -row 4 -column 0 -sticky news
grid .pyre_version -row 4 -column 1 -sticky news


# === STARTUP COMMANDS ===
ping_database_server
