#!/bin/bash
export LIST_FN_PREFIX="devstats-helm/all_"
failed=''
. ./devel/all_dbs.sh || exit 2
for db in $all
do
  echo "$db"
 ./devstats-helm/restore_artificial.sh "$db"
  if [ ! "$?" = "0" ]
  then
    echo "$db failed, proceeding"
    if [ -z "$failed" ]
    then
      failed="$db"
    else
      failed="$failed $db"
    fi
  fi
done
if [ ! -z "$failed" ]
then
  echo "Failed: $failed"
  exit 1
else
  echo "All backups restore OK"
fi
