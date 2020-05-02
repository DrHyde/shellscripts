#!/bin/bash

set -eu -o pipefail

[[ "$1" =~ ^http.* ]] && echo "Provide a Youtube ID, not a URL" && exit 1

renice -n 19 -p $$

SUBSLANG="$(youtube-dl --list-subs -- "$1"|grep ^en|tail -1|cut -d ' ' -f1)"

youtube-dl -f 136+140 --sub-lang $SUBSLANG --write-sub -- "$1"

MP4="$(ls ./*$1*.mp4)"
VTT="$(ls ./*$1*.vtt)"
mv "$MP4" $$-input.mp4
mv "$VTT" $$-input.vtt

# and here beginneth the subtitle job
ffmpeg -loglevel quiet -stats -i $$-input.mp4 -i $$-input.vtt -c copy -c:s mov_text "$MP4"

# clean up
rm $$-input.{vtt,mp4}
