#!/bin/bash

packwiz update --all
packwiz refresh
git add .
git commit -m "Update mods"