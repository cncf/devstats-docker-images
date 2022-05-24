#!/bin/bash
ls /grafana && rm -rf /usr/share/nginx/html/backups/grafana && mv /grafana /usr/share/nginx/html/backups/grafana
mv replacer sqlitedb runq /usr/share/nginx/html/backups/grafana
nginx -g 'daemon off;'
