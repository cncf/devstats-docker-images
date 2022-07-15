#!/bin/bash
if [ ! -z "${REINIT_SHARED_GRAFANA}" ]
then
  ls /grafana && rm -rf /usr/share/nginx/html/backups/grafana && mv /grafana /usr/share/nginx/html/backups/grafana
  mv replacer sqlitedb runq /usr/share/nginx/html/backups/grafana
fi
nginx -g 'daemon off;'
