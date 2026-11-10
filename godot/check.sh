#!/bin/sh
# Compile-check every script; prints a de-duplicated summary of parse errors.
cd "$(dirname "$0")"
timeout 300 godot --headless --path . --import > /tmp/import.log 2>&1
grep -A1 "Parse Error" /tmp/import.log | grep -v "^--" | paste - - | sed 's/SCRIPT ERROR: Parse Error: //; s/ *at: GDScript::reload (res:\/\//  @ /; s/)$//' | sort -u > /tmp/errs.txt
echo "errors: $(wc -l < /tmp/errs.txt)"
head -${1:-40} /tmp/errs.txt
