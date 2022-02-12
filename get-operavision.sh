#!/bin/bash

set -eu -o pipefail

[[ "$1" =~ ^http.* ]] && echo "Provide a Youtube ID, not a URL" && exit 1

renice -n 19 -p $$

SUBSLANG="$(yt-dlp --list-subs -- "$1"|grep ^en|tail -1|cut -d ' ' -f1)" || true

if [[ "$SUBSLANG" != "" ]]; then
    SUBSLANG="--sub-lang $SUBSLANG --write-sub"
fi

yt-dlp -f 136+140 $SUBSLANG -- "$1"

VTT="$(ls ./*$1*.vtt 2>/dev/null)" || true
if [[ $VTT != "" ]]; then
    MP4="$(ls ./*$1*.mp4)"
    mv "$MP4" $$-input.mp4
    mv "$VTT" $$-input.vtt
    ffmpeg -loglevel quiet -stats -i $$-input.mp4 -i $$-input.vtt -c copy -c:s mov_text "$MP4"
    rm $$-input.{vtt,mp4}
fi
