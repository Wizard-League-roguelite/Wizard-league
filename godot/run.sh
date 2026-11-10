#!/bin/sh
# Runs the game under a virtual display with a driver script (see dev/Driver.gd).
cd "$(dirname "$0")"
timeout ${TIMEOUT:-50} xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution ${RES:-1280x720} -- --driver="$1" 2>&1 | grep -v "^Godot Engine\|^OpenGL API\|^$\|libEGL\|MESA\|glx"
