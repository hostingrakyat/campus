#!/usr/bin/env bash
# Parse-checks every GDScript file in the project. Usage: tools/check_scripts.sh
cd "$(dirname "$0")/.."
fail=0
for f in $(find scripts tests -name "*.gd"); do
  out=$(timeout 60 godot --headless --check-only --script "res://$f" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|error" | grep -v "Failed to compile depended" | head -5)
  if [ -n "$out" ]; then echo "== $f"; echo "$out"; fail=1; fi
done
[ $fail -eq 0 ] && echo "ALL SCRIPTS OK"
exit $fail
