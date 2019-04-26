#!/bin/bash
files=`find ./metrics/ -name vars.yaml` || exit 1
for fn in $files
do
  echo $fn
  MODE=ss0 FROM="hostname, os_hostname" TO="hostname, ':devstats-demo.net'" replacer "$fn"
  MODE=ss0 FROM="':prodsrv=devstats.cncf.io '" TO="':prodsrv=devstats-demo.net '" replacer "$fn"
  MODE=ss0 FROM="': devstats.cncf.io=prodsrv'" TO="': devstats-demo.net=prodsrv'" replacer "$fn"
done
echo 'Patching OK'
