#!/bin/bash
cwd="`pwd`"
cd ../devstats || exit 1
cd ../devstatscode || exit 2

rm -f ../devstats-docker-lf/devstatscode.tar 2>/dev/null
tar cf ../devstats-docker-lf/devstatscode.tar cmd vendor *.go

cd ../devstats || exit 3
rm -f ../devstats-docker-lf/devstats.tar 2>/dev/null
tar cf ../devstats-docker-lf/devstats.tar git metrics devel util_sql all cdf lfn shared iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord scripts partials docs cron util_sh/make_binary_links.sh projects.yaml companies.yaml skip_dates.yaml linux.yaml zephyr.yaml github_users.json

cd "$cwd" || exit 4
rm -f devstats-docer-lf.tar 2>/dev/null
tar cf devstats-docker-lf.tar docker

docker build -f ./docker/Dockerfile.minimal -t devstats-minimal-lfda .
rm -f devstats.tar devstatscode.tar devstats-docker-lf.tar
