package require platform

set HERE [file dirname $argv0]
set IMG_DIR [file join ${HERE} "img"]
set APP_NAME "Rite Club Companion"
set PYRE_LOCATION "(unset)"

set fp [open "${HERE}/VERSION"]
set _version [read $fp]
close $fp
set VERSION [string trim ${_version}]

image create photo pyre_logo -file "${IMG_DIR}/pyre.png"

wm title . ${APP_NAME}
wm iconphoto . -default pyre_logo
wm geometry . "=800x600"
wm resizable . true true

#########

ttk::label .title_label_img -image pyre_logo

proc destroy_about_window {} {
  wm withdraw .about_window
  wm forget .about_window
}

# XXX Can't show this window twice! 
proc show_about_window {} {
  global APP_NAME
  global VERSION

  toplevel .about_window
  wm title .about_window "About ${APP_NAME}"
  wm geometry .about_window "=300x150"

  ttk::label .about_window.version_text -text "${APP_NAME} ${VERSION}\nDeveloped by Charlotte Koch"
  ttk::button .about_window.ok_button -text "OK" -command destroy_about_window

  pack .about_window.version_text
  pack .about_window.ok_button
}

ttk::button .button1 -text "click me" -command show_about_window

proc set_pyre_location {} {
  global PYRE_LOCATION

  if [string match "macosx" [platform::generic]] {
    set PYRE_LOCATION [::tk::mac::OpenApplication]
  } else {
    set PYRE_LOCATION [tk_getOpenFile -parent .]
  }
}

ttk::button .choose_pyre_button -text "Choose Pyre..."  -command set_pyre_location

ttk::label .pyre_location_label -text "Pyre location:"
ttk::label .pyre_location -textvariable PYRE_LOCATION

#########

pack .title_label_img
pack .button1
pack .choose_pyre_button
pack .pyre_location_label
pack .pyre_location
