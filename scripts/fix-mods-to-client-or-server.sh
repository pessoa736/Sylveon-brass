#!/bin/bash

set_side() {
  local side="$1"
  local mods_file="$2"
  local mod

  while IFS= read -r mod; do
    [[ -z "$mod" || "$mod" == \#* ]] && continue

    file="mods/${mod}.pw.toml"

    if [ -f "$file" ]; then
      sed -i -E "s/^side = \".*\"/side = \"${side}\"/" "$file"
      echo "Set $mod to $side"
    fi
  done < "$mods_file"
}

set_side "client" "$(dirname "$0")/client-mods.txt"
set_side "both" "$(dirname "$0")/both-mods.txt"
set_side "server" "$(dirname "$0")/server-mods.txt"

packwiz refresh