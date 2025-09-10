#!/bin/bash

pushd "$(dirname "$0")" > /dev/null


frame_image () {
    screenshot="$1"
    echo "processing $screenshot"

    screenshotdir=$(dirname "$screenshot")
    screenshotfile=$(basename "$screenshot")

    dashcount=$(echo "$screenshotfile"| tr -dc "-" | awk '{ print length; }')

    # turn "./screenshots/en-US/iPhone 16 Pro-..." into "iPhone 16 Pro"
    device=$(echo "$screenshotfile" | cut -d "-" -f "1-$dashcount")

    frame="./resources/$device-frame.png"
    mask="./resources/$device-mask.png"

    maskedfile="$screenshotdir/masked-$screenshotfile"

    if [ ! -f "$mask" ]; then
        cp "$screenshot" "$maskedfile"
    else
        # mask off the corners of the screenshot
        magick "$screenshot" "$mask" -alpha Off -compose CopyOpacity -composite "$maskedfile"
    fi

    framedfile=$(echo "$screenshot" | sed 's|./screenshots|./framed|g')

    mkdir -p $(dirname "$framedfile")

    magick composite -gravity center -compose dst-over "$maskedfile" "$frame" "$framedfile"

    rm "$maskedfile"
}

export -f frame_image

find ./output -not -path '*/.*' -type f -depth 2 -exec bash -c 'frame_image "$1"' _ "{}" \;


popd > /dev/null
