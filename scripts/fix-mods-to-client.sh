#!/bin/bash

CLIENT_MODS=(
  "sodium"
  "irisshaders"
  "entityculling"
  "immediatelyfast"
  "dynamiclights-reforged"
  "reeses-sodium-options"
  "sodium-extra"
  "sodium-options-api"
  "controlling"
  "item-borders"
  "item-highlighter"
  "jei"
  "just-zoom"
  "legendary-tooltips"
  "mouse-tweaks"
  "trashslot"
  "xaeros-minimap"
  "xaeros-world-map"
  "appleskin"
  "chiselmon"
)

for mod in "${CLIENT_MODS[@]}"; do
  file="mods/${mod}.pw.toml"

  if [ -f "$file" ]; then
    sed -i 's/side = "both"/side = "client"/' "$file"
    echo "Fixed $mod"
  fi
done

packwiz refresh