#!/bin/bash

pushd "$(dirname "$0")" > /dev/null


frame_image () {
    screenshot="$1"
    echo "processing $screenshot"

    screenshotdir=$(dirname "$screenshot")
    screenshotfile=$(basename "$screenshot")

    # turn "iPad Pro 13-inch (M4)-..." into "iPad Pro 13-inch (M4)"
    dashcount=$(echo "$screenshotfile"| tr -dc "-" | awk '{ print length; }')
    device=$(echo "$screenshotfile" | cut -d "-" -f "1-$dashcount")

    frame="./resources/$device-frame.png"
    mask="./resources/$device-mask.png"

    maskedfile="$screenshotdir/masked-$screenshotfile"

    if [ ! -f "$frame" ]; then
        return
    fi

    if [ ! -f "$mask" ]; then
        cp "$screenshot" "$maskedfile"
    else
        # mask off the corners of the screenshot
        magick "$screenshot" "$mask" -alpha Off -compose CopyOpacity -composite "$maskedfile"
    fi

    framedfile=$(echo "$screenshot" | sed 's|./output|./framed|g')

    mkdir -p $(dirname "$framedfile")

    magick composite -gravity center -compose dst-over "$maskedfile" "$frame" "$framedfile"

    rm "$maskedfile"
}

export -f frame_image

find ./output -not -path '*/.*' -type f -depth 2 -exec bash -c 'frame_image "$1"' _ "{}" \;


popd > /dev/null
