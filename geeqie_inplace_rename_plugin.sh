#!/bin/bash

# in-place rename action for geeqie
# since the default keybind <ctrl-r> opens
# a FUCKING-MESSED-UP dialog windows
# instead of the normal and sane in-place renaming
# action of <mouse rigth-click> -> "rename".
# Not a great solution, but one of the few possible
# so far... Cfr. https://github.com/BestImageViewer/geeqie/issues/1481

sleep 0.1
#
xdotool key Menu
#
sleep 0.1
xdotool key Down Down Down Down Down
sleep 0.1
xdotool key Return
