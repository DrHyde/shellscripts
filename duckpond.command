#!/bin/sh

TERM=vt100 ssh -o ServerAliveInterval=30 -t david@duckpond.barnyard.co.uk "$@"
