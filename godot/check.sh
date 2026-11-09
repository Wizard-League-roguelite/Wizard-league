#!/bin/sh
# Compile-check every script; prints a summary of parse errors.
cd "$(dirname "$0")"
timeout 300 godot --headless --path . --import > /tmp/import.log 2>&1
echo "errors: $(grep -c 'Parse Error' /tmp/import.log)"
grep -A1 "Parse Error" /tmp/import.log | grep -v "^--" | paste - - | sed 's/SCRIPT ERROR: Parse Error: //; s/ *at: GDScript::reload (res:\/\//  @ /; s/)$//' | head -${1:-40}
