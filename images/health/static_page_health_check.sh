#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need to specify server url as an argument"
  exit 1
fi
wget -qO- "${1}/all.svg" | grep svg
