#!/bin/bash
for f in $*
do
  fn="../devstats/metrics/$f/vars.yaml"
  #fn="./metrics/$f/vars.yaml"
  echo $fn
  MODE=ss0 FROM="hostname, os_hostname" TO="hostname, ':devstats-demo.net'" replacer "$fn"
  MODE=ss0 FROM="':prodsrv=devstats.cncf.io '" TO="':prodsrv=devstats-demo.net '" replacer "$fn"
  MODE=ss0 FROM="': devstats.cncf.io=prodsrv'" TO="': devstats-demo.net=prodsrv'" replacer "$fn"
done
echo 'Patching OK'
