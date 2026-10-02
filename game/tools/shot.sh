#!/usr/bin/env bash
# Renders one screen to PNG via Xvfb. Usage: tools/shot.sh <scene> [outdir]
# Scenes: title note create ukt ukt_phk krs war week event picker shop wardrobe jobs academic khs ending_<id> gallery
cd "$(dirname "$0")/.."
OUT=${2:-/tmp/claude-0/shots}
mkdir -p "$OUT" /tmp/claude-0/shothome
rm -rf /tmp/claude-0/shothome/.local/share/godot/app_userdata
RES=${RES:-720x1280}
timeout 90 xvfb-run -a -s "-screen 0 ${RES}x24" env HOME=/tmp/claude-0/shothome XDG_DATA_HOME=/tmp/claude-0/shothome/.local/share \
  godot --rendering-driver opengl3 --resolution $RES -- --shot="$1" --out="$OUT/$1${TAG}.png" 2>&1 \
  | grep -E "SCRIPT ERROR|Parse Error|Invalid|at: |SHOT" | grep -v "leaked" | head -20
