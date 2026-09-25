#!/bin/bash
# GIANT=lock|wait|'' lock giant lock or only wait for giant lock or do not use giant lock
# NOAGE=1 - always backup databases, do not check minimum age + randomize
# SKIP_FLAGS=1 - do not check per-DB 'provisioned'/'devstats_running' flags before backups
# BACKUP_WAIT_MAX=28800 - max seconds to wait for a busy DB (not provisioned / sync running) before skipping it
# BACKUP_WAIT_STEP=60 - seconds between busy re-checks
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
function db_busy {
  # prints why DB $1 is being actively updated, empty when idle; a 'devstats_running' flag older than 9h is an orphan (same as the devstats tool)
  db.sh psql "$1" -tAc "select coalesce((select 'not provisioned' where not exists (select 1 from gha_computed where metric = 'provisioned')), (select 'sync running since ' || dt::text from gha_computed where metric = 'devstats_running' and dt > now() - interval '9 hours' order by dt desc limit 1), '')" 2>/dev/null
}
function wait_idle {
  # wait_idle db what: 0 when DB is idle, 1 when still busy after BACKUP_WAIT_MAX seconds
  local waited=0 reason
  while true
  do
    reason=`db_busy "$1"`
    if [ -z "$reason" ]
    then
      return 0
    fi
    if (( waited >= wait_max ))
    then
      echo "`date '+%Y-%m-%d %H:%M:%S'` $1 still busy after ${waited}s ($reason), skipping $2"
      return 1
    fi
    if (( waited % 600 == 0 ))
    then
      echo "`date '+%Y-%m-%d %H:%M:%S'` $1 is busy ($reason), waiting before $2 (${waited}s so far)"
    fi
    sleep "$wait_step"
    waited=$((waited+wait_step))
  done
}
wait_max="${BACKUP_WAIT_MAX:-28800}"
wait_step="${BACKUP_WAIT_STEP:-60}"
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
    if ! wait_idle "$db" "artificial events backup"
    then
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
      if ! wait_idle "$db" "full backup"
      then
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
  echo "`date '+%Y-%m-%d %H:%M:%S'` Skipped backups (still not provisioned or sync still running after ${wait_max}s): $skipped"
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
