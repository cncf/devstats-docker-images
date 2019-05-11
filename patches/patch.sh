#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to specify host type as a first arg: prodsrv or testsrv"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: you need to specify hostname: devstats-demo.net, graphql.devstats.org etc."
  exit 2
fi
if [ "$1" = "prodsrv" ]
then
  fromh='devstats.cncf.io'
elif [ "$1" = "testsrv" ]
then
  fromh='teststats.cncf.io'
else
  echo "$0: 1st arg must be either prodsrv or testsrv, got: $1"
  exit 3
fi
files=`find ./metrics/ -name vars.yaml -o -name sync_vars.yaml` || exit 4
for fn in $files
do
  echo "Patching $fn"
  MODE=ss0 FROM="hostname, os_hostname" TO="hostname, ':$2'" replacer "$fn"
  MODE=ss0 FROM="':$1=$fromh '" TO="':$1=$2 '" replacer "$fn"
  MODE=ss0 FROM="': $fromh=$1'" TO="': $2=$1'" replacer "$fn"
done
echo 'Patching OK'
