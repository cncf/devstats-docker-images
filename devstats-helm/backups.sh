#!/bin/bash
. ./devel/all_dbs.sh || exit 2
for db in $all
do
 ./devstats-helm/backup_artificial.sh "$db" || exit 1
done
