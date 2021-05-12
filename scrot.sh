#!/bin/bash
while getopts "st:" arg
do
  case $arg in
    s)
      S="-s"
      ;;
    t)
      sleep $OPTARG #gia to bug, integer 8elei
      ;;
  esac
done
scrot $S '%Y-%m-%d_$wx$h.png' -e 'mv $f ~/Screenshots'
#todo: notification me action gia stokinhto.sh
