#!/bin/bash
filename=/tmp/$(date '+%F-%H%M%S').png
qrencode -o $filename "$1"
feh --zoom max $filename
