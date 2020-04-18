#!/bin/bash

set -eu -o pipefail

[[ "$1" =~ ^http.* ]] && echo "Provide a Youtube ID, not a URL" && exit 1

renice -n 19 -p $$

wait_in_queue() {
    echo Entering queue $1
    local queue_file="$HOME/.get-operavision/${1}_pid"
    mkdir "$HOME/.get-operavision" 2>/dev/null || true
    while [[ -f "$queue_file" ]]; do
        kill -0 $(cat "$queue_file") 2>/dev/null || break
        sleep 60
    done
    echo $$ > "$queue_file"
    echo Leaving queue
}

unlock_queue() {
    echo Unlocking queue $1
    local queue_file="$HOME/.get-operavision/${1}_pid"
    rm "$queue_file"
}

SUBSLANG="$(youtube-dl --list-subs "$1"|grep ^en|tail -1|cut -d ' ' -f1)"

# here beginneth the fetch job
time -p wait_in_queue fetch
youtube-dl -f 136+140 --sub-lang $SUBSLANG --write-sub "$1"
unlock_queue fetch

MP4="$(ls ./*$1*.mp4)"
VTT="$(ls ./*$1*.vtt)"
mv "$MP4" $$-input.mp4
mv "$VTT" $$-input.vtt

# and here beginneth the subtitle job
time -p wait_in_queue subtitle
ffmpeg -loglevel repeat+info -i $$-input.mp4 -vf subtitles=$$-input.vtt "$MP4"
unlock_queue subtitle

# clean up
rm $$-input.{vtt,mp4}
