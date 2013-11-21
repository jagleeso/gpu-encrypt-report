#!/usr/bin/env bash
eps="$1"
shift 1

png="${eps%.*}.png"
convert -density 300 $eps -resize 1024x1024 $png
