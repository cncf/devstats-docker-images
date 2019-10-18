#!/bin/bash
export LIST_FN_PREFIX="devstats-helm/all_"
failed=''
failed_full=''
nfull=0
week="604800"
day="86400"
. ./devel/all_dbs.sh || exit 2
for db in $all
do
  echo "`date '+%Y-%m-%d %H:%M:%S'` $db"
  ./devstats-helm/backup_artificial.sh "$db"
  if [ ! "$?" = "0" ]
  then
    echo "`date '+%Y-%m-%d %H:%M:%S'` failed, proceeding"
    if [ -z "$failed" ]
    then
      failed="$db"
    else
      failed="$failed $db"
    fi
  fi
  age=`./devel/file_age.sh "/root/$db"`
  if [ "$age" = "no" ]
  then
    age=$((day*5))
  fi
  rage=$(((day*4)+(RANDOM*19)%week))
  if (( age > rage ))
  then
    echo "`date '+%Y-%m-%d %H:%M:%S'` full $db"
    db.sh pg_dump -Fc "$db" -f "/root/$db.dump"
    if [ ! "$?" = "0" ]
    then
      echo "`date '+%Y-%m-%d %H:%M:%S'` $db full backup failed, proceeding"
      if [ -z "$failed_full" ]
      then
        failed_full="$db"
      else
        failed_full="$failed_full $db"
      fi
    fi
    nfull=$((nfull+1))
  fi
done
if [ ! -z "$failed" ]
then
  echo "`date '+%Y-%m-%d %H:%M:%S'` Failed artificial events backups: $failed"
else
  echo "`date '+%Y-%m-%d %H:%M:%S'` All artificial events backups OK"
fi
if [ ! -z "$failed_full" ]
then
  echo "`date '+%Y-%m-%d %H:%M:%S'` Failed full backups: $failed_full"
else
  if (( nfull > 0 ))
  then
    echo "`date '+%Y-%m-%d %H:%M:%S'` $nfull full backups OK"
  fi
fi
