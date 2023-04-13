#!/bin/bash

set -e

DATA_DIR=/data/mainuser/screenrec

mkdir -p "$DATA_DIR"

sleep 10

while :; do
    ffmpeg -framerate 3 -f x11grab -i :0.0 \
        -c:v libx265 -crf 40 -preset slow \
        -vf 'scale=iw*2/3:ih*2/3' -t 60 \
        "$DATA_DIR/$(date +%Y-%m-%d-%H%M%S).mp4"
done
