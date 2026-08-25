#!/bin/bash
# GIANT=lock|wait|'' lock giant lock or only wait for giant lock or do not use giant lock
# NOAGE=1 - always backup databases, do not check minimum age + randomize
# SKIP_FLAGS=1 - do not check per-DB 'provisioned'/'devstats_running' flags before backups
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
skipped=''
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
  if [ -z "$SKIP_FLAGS" ]
  then
    provisioned=`db.sh psql "$db" -tAc "select 1 from gha_computed where metric = 'provisioned' union select 0 order by 1 desc limit 1" 2>/dev/null`
    if [ "$provisioned" = "0" ]
    then
      echo "`date '+%Y-%m-%d %H:%M:%S'` $db is not provisioned (provisioning/reinit in progress?), skipping"
      if [ -z "$skipped" ]
      then
        skipped="$db"
      else
        skipped="$skipped $db"
      fi
      continue
    fi
  fi
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
  age=`./devel/file_age.sh "/root/${db}.dump"`
  if [ "$age" = "no" ]
  then
    age=$((day*6))
  fi
  rage=$(((day*4)+(RANDOM*19)%week))
  if ((( age > rage )) || [ ! -z "$NOAGE" ])
  then
    if [ -z "$SKIP_FLAGS" ]
    then
      running=`db.sh psql "$db" -tAc "select 1 from gha_computed where metric = 'devstats_running' limit 1" 2>/dev/null`
      if [ "$running" = "1" ]
      then
        echo "`date '+%Y-%m-%d %H:%M:%S'` $db sync is running, skipping full backup this run"
        if [ -z "$skipped" ]
        then
          skipped="$db"
        else
          skipped="$skipped $db"
        fi
        continue
      fi
    fi
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
exists=`db.sh psql postgres -tAc "select 1 from pg_database where datname = 'affiliations'"`
if [ "$exists" = "1" ]
then
  age=`./devel/file_age.sh "/root/affiliations.dump"`
  if [ "$age" = "no" ]
  then
    age=$((day*2))
  fi
  if ((( age > day )) || [ ! -z "$NOAGE" ])
  then
    echo "`date '+%Y-%m-%d %H:%M:%S'` full affiliations (shared actors/affiliations data)"
    db.sh pg_dump -Fc "affiliations" -f "/root/affiliations.dump"
    if [ ! "$?" = "0" ]
    then
      echo "`date '+%Y-%m-%d %H:%M:%S'` affiliations full backup failed, proceeding"
      if [ -z "$failed_full" ]
      then
        failed_full="affiliations"
      else
        failed_full="$failed_full affiliations"
      fi
    fi
    nfull=$((nfull+1))
  fi
fi
if [ ! -z "$skipped" ]
then
  echo "`date '+%Y-%m-%d %H:%M:%S'` Skipped backups (not provisioned or sync running): $skipped"
fi
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
