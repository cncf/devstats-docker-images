#!/bin/bash
ln -s /root/grafana /grafana
cp grafana/shared/install_plugins.sh /usr/bin/
# install_plugins.sh
# service grafana-server restart
cp replacer sqlitedb grafana/shared/expose_grafana_db.sh grafana/shared/grafana_health_check.sh /usr/bin/
cp grafana/shared/grafana_start.sh /usr/bin/grafana_start_internal.sh
grafana_start_internal.sh
