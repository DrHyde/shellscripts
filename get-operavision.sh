#!/bin/bash

set -eu -o pipefail

renice -n 19 -p $$

OPERA_TEMPDIR="get-opera-$$"

mkdir "$OPERA_TEMPDIR"
(
    cd "$OPERA_TEMPDIR"
    youtube-dl -f 136+140 --sub-lang en-GB --write-sub "$@"
    MP4="$(ls ./*.mp4)"
    VTT="$(ls ./*.vtt)"
    mv "$MP4" input.mp4
    ffmpeg -i input.mp4 -vf subtitles="$VTT" "$MP4"
    mv "$MP4" ..
)
rm -rf "$OPERA_TEMPDIR"
