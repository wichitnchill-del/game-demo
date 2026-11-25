#!/bin/bash
# Double-click to play Core Blaker (macOS).
DIR="$(cd "$(dirname "$0")" && pwd)"
GODOT="$DIR/engine/Godot.app/Contents/MacOS/Godot"
if [ ! -x "$GODOT" ]; then
  echo "ไม่พบ Godot ที่ $GODOT"
  read -p "กด Enter เพื่อปิด"
  exit 1
fi
exec "$GODOT" --path "$DIR/godot"
