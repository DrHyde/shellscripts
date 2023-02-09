#!/bin/sh

export TERM=vt100

if [ "$(hostname)" == "mac-dcantrell" ]; then
    mosh -- david@duckpond.barnyard.co.uk ssh -t david@bytemark.barnyard.co.uk "$@"
else
    ssh -o ServerAliveInterval=30 -t david@bytemark.barnyard.co.uk "$@"
fi
