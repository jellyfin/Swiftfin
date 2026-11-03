#!/bin/bash
# Copyright (c) 2026 Jellyfin & Jellyfin Contributors. SPDX-License-Identifier: MPL-2.0
set -u

device=$1
screenshots="$HOME/Library/Caches/tools.fastlane/screenshots"
owner=$PPID
pose() { hinge --device "$device" "$@"; }

# XCTest puts a request beside the PNG that fastlane will collect.
rm -f "$screenshots/$device-"*.png.request
while kill -0 "$owner" 2>/dev/null; do
    for request in "$screenshots/$device-"*.png.request; do
        [[ -f "$request" ]] || continue
        png=${request%.request}
        temp="$request.partial.png"
        rm -f "$png" "$temp"

        saved=false
        if pose open && pose orient "$(cat "$request")" && sleep 2 && pose screenshot "$temp"; then
            saved=true
        fi
        if pose close && pose orient portrait && "$saved"; then
            mv "$temp" "$png"
        fi
        rm -f "$temp" "$request"
    done
    sleep 0.25
done
