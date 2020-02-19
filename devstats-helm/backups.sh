#!/bin/bash
# GIANT=lock|wait|'' lock giant lock or only wait for giant lock or do not use giant lock
# NOAGE=1 - always backup databases, do not check minimum age + randomize
if [ ! -z "$GIANT" ]
then
  ./devel/wait_flag.sh devstats giant_lock 0 60 || exit 3
  if [ "$GIANT" = "lock" ]
  then
    ./devel/set_flag.sh devstats giant_lock || exit 4
  fi
fi
function clear_flag {
  ./devel/clear_flag.sh devstats giant_lock
}
if [ "$GIANT" = "lock" ]
then
  trap clear_flag EXIT
fi
export LIST_FN_PREFIX="devstats-helm/all_"
failed=''
failed_full=''
nfull=0
week="604800"
day="86400"
. ./devel/all_dbs.sh || exit 2
if [ ! -z "$NOAGE" ]
then
  echo "Force backup $all"
fi
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
  if ((( age > rage )) || [ ! -z "$NOAGE" ])
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
