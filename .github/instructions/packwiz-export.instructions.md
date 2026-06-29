---
description: "Use when editing, debugging, or running the packwiz export scripts (scripts/export-client.sh, scripts/export-server.sh). Covers the export pipeline, RAM injection via jq, and the server-side variant."
applyTo: "scripts/export-*.sh"
---

# Packwiz Export Scripts

The pack has two export scripts that produce CurseForge-compatible zips:

| Script | Command | RAM injected | Output |
|---|---|---|---|
| `scripts/export-client.sh` | `packwiz curseforge export` | `6144` MB | Client-side zip (all mods) |
| `scripts/export-server.sh` | `packwiz curseforge export -s server` | `4096` MB | Server-side zip (no client-only mods) |

## Pipeline (both scripts)

1. Run `packwiz curseforge export` (with `-s server` for the server variant).
2. Auto-detect the generated zip via `ls Sylveon*.zip | head -n 1`.
3. `mkdir -p build && mv` the zip into `build/`.
4. `cd build && unzip -q <zip> manifest.json`.
5. Patch with `jq --argjson ram <N> '. + {recommendedMemory: $ram}' manifest.json > manifest.tmp && mv manifest.tmp manifest.json`.
6. `zip -q -u <zip> manifest.json` to update the zip in place.
7. `rm manifest.json` (the extracted copy) and `cd ..`.

## Hard rules

- **Never commit the generated zip** in `build/`. It is gitignored.
- **Never hand-edit `manifest.json` inside the zip** — always go through the script so the change is reproducible.
- **Server RAM is 4096 MB, client RAM is 6144 MB.** Do not change these without a reason — they are tuned for the pack's expected load.
- The server-side export (`-s server`) relies on each `mods/*.pw.toml` having the correct `side = "client" | "server" | "both"` field. If a mod is missing from the server zip, check `scripts/fix-mods-to-client-or-server.sh` and the `side` field on the corresponding `*.pw.toml`.
- The zip contains **no `.jar` files** — only `manifest.json`, `modlist.html`, and `overrides/`. Mods are downloaded by the launcher at install time. This is expected, not a bug.

## When debugging

- If the script produces no output, run it with `bash -x scripts/export-server.sh` to trace each command.
- If `packwiz` is missing, install it from https://github.com/packwiz/packwiz.
- If `jq` fails on `manifest.json`, validate the JSON first: `jq . build/<zip-extracted>/manifest.json`.
