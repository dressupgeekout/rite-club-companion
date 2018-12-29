#!/usr/bin/env tclsh8.6
#
# by Charlotte Koch <dressupgeekout@gmail.com>
#
# This program emulates the setup screen for setting up a "versus" session
# in Pyre, and then reports to you the choices that were made. The intention
# behind this report is to capture all the data that makes up a rite, which
# could then be stored into a database or whatever you want.
#

package require Tk

##########

set VERSION "0.0.0"

set TRIUMVIRATES [list \
  Accusers             \
  Beyonders            \
  Chastity             \
  Fate                 \
  Nightwings           \
  {True Nightwings}    \
]

set LANDMARKS [list \
  {Fall of Soliam}  \
  {Glade of Lu}     \
  {Nest of Triesta} \
]

set EXILES [list     \
  Barker             \
  Hedwyn             \
  Jodariel           \
  Oralech            \
  Pamitha            \
  Rukey              \
  Sandra             \
  Tamitha            \
  Volfred            \
  Xae                \
  {Big Bertrude}     \
  {Ti'zo}            \
  {Sir Gilman}       \
  {Messenger-Imp}    \
]

set INPUT_METHODS [list \
  CONTROLLER            \
  KEYBOARD              \
  MOUSE                 \
]

set TITAN_STARS [list \
  [dict create name "" description ""]
]

##########

proc report_version {} {
  global VERSION
  puts $VERSION
}

proc full_report {} {
  global rite.location
  global rite.player1.input_method
  global rite.player1.name
  global rite.player1.triumvirate
  global rite.player2.input_method
  global rite.player2.name
  global rite.player2.triumvirate
  global rite.talismans_enabled?

  puts [string cat "player1: " ${rite.player1.triumvirate}]
  puts [string cat "player2: " ${rite.player2.triumvirate}]
  puts [string cat "location: " ${rite.location}]
  puts [string cat "talismans enabled: " ${rite.talismans_enabled?}]
}

##########

wm title . "Pyre"

set rite.location {}
set rite.player1.input_method {}
set rite.player1.name {}
set rite.player1.triumvirate {}
set rite.player2.input_method {}
set rite.player2.name {}
set rite.player2.triumvirate {}
set rite.talismans_enabled? 0

ttk::button .button1 -text "Click me!" -command full_report

ttk::label .player1_name_entry_label -text "Player 1 Name"
ttk::entry .player1_name_entry -textvariable rite.player1.name

ttk::label .player2_name_entry_label -text "Player 2 Name"
ttk::entry .player2_name_entry -textvariable rite.player2.name

ttk::label .player1_triumvirate_selection_label -text "Player 1 Triumvirate"
ttk::combobox .player1_triumvirate_selection -values ${TRIUMVIRATES} -textvariable rite.player1.triumvirate

ttk::label .player2_triumvirate_selection_label -text "Player 2 Triumvirate"
ttk::combobox .player2_triumvirate_selection -values ${TRIUMVIRATES} -textvariable rite.player2.triumvirate

ttk::label .player1_input_method_selection_label -text "Player 1 Input Method"
ttk::combobox .player1_input_method_selection -values ${INPUT_METHODS} -textvariable rite.player1.input_method

ttk::label .player2_input_method_selection_label -text "Player 2 Input Method"
ttk::combobox .player2_input_method_selection -values ${INPUT_METHODS} -textvariable rite.player2.input_method

ttk::label .location_selection_label -text "Location"
ttk::combobox .location_selection -values ${LANDMARKS} -textvariable rite.location

ttk::label .talisman_checkbox_label -text "Talismans enabled?"
ttk::checkbutton .talisman_checkbox -variable rite.talismans_enabled?

pack .player1_name_entry_label
pack .player1_name_entry
pack .player2_name_entry_label
pack .player2_name_entry
pack .player1_triumvirate_selection_label
pack .player1_triumvirate_selection
pack .player2_triumvirate_selection_label
pack .player2_triumvirate_selection
pack .player1_input_method_selection_label 
pack .player1_input_method_selection
pack .player2_input_method_selection_label 
pack .player2_input_method_selection
pack .location_selection_label
pack .location_selection
pack .talisman_checkbox_label
pack .talisman_checkbox
pack .button1
