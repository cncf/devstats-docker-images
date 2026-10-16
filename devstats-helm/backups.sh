#!/bin/bash
# GIANT=lock|wait|'' lock giant lock or only wait for giant lock or do not use giant lock
# Every selected database is backed up sequentially; NOAGE is no longer needed.
# SKIP_FLAGS=1 - do not check provisioning, sync or shared affiliations flags before backups
# BACKUP_WAIT_MAX=0 - wait indefinitely; a positive limit skips busy DBs and fails the run
# BACKUP_WAIT_STEP=60 - seconds between busy re-checks
wait_max="${BACKUP_WAIT_MAX:-0}"
wait_step="${BACKUP_WAIT_STEP:-60}"
if ! [[ "$wait_max" =~ ^[0-9]+$ && "$wait_step" =~ ^[0-9]+$ ]]
then
  echo "BACKUP_WAIT_MAX must be a nonnegative integer and BACKUP_WAIT_STEP a positive integer" >&2
  exit 2
fi
wait_max=$((10#$wait_max))
wait_step=$((10#$wait_step))
if (( wait_max < 0 || wait_step <= 0 ))
then
  echo "Invalid backup wait limits: $wait_max / $wait_step" >&2
  exit 2
fi
export PGOPTIONS="${PGOPTIONS:+$PGOPTIONS }-c max_parallel_workers_per_gather=0 -c work_mem=16MB"
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
  local reason
  reason=$(db.sh psql devstats -X -v ON_ERROR_STOP=1 -tAc "select coalesce((select 'affiliations import running' where exists (select 1 from gha_locks where name = 'affs_lock') or exists (select 1 from gha_computed where metric = 'affs_lock')), '')") || return 1
  if [ ! -z "$reason" ]
  then
    echo "$reason"
    return 0
  fi
  if [ "$1" = "affiliations" ]
  then
    return 0
  fi
  # Long legitimate syncs must not become idle merely because their flag is old.
  db.sh psql "$1" -X -v ON_ERROR_STOP=1 -tAc "select coalesce((select 'not provisioned' where not exists (select 1 from gha_computed where metric = 'provisioned')), (select 'sync running since ' || dt::text from gha_computed where metric = 'devstats_running' order by dt desc limit 1), '')"
}
function wait_idle {
  local waited=0 next_log=0 reason
  while true
  do
    if ! reason=$(db_busy "$1")
    then
      echo "`date '+%Y-%m-%d %H:%M:%S'` Cannot check $1 activity, refusing $2" >&2
      return 2
    fi
    if [ -z "$reason" ]
    then
      return 0
    fi
    if (( wait_max > 0 && waited >= wait_max ))
    then
      echo "`date '+%Y-%m-%d %H:%M:%S'` $1 still busy after ${waited}s ($reason), skipping $2"
      return 1
    fi
    if (( waited >= next_log ))
    then
      echo "`date '+%Y-%m-%d %H:%M:%S'` $1 is busy ($reason), waiting before $2 (${waited}s so far)"
      next_log=$((waited+600))
    fi
    sleep "$wait_step" || return 2
    waited=$((waited+wait_step))
  done
}
function dump_full {
  local dump="/root/$1.dump.$$"
  if db.sh pg_dump -Fc -Z1 "$1" -f "$dump" && mv -f "$dump" "/root/$1.dump"
  then
    return 0
  fi
  rm -f "$dump"
  return 1
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
. ./devel/all_dbs.sh || exit 2
echo "Sequential backup of all selected databases: $all"
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
  if ! dump_full "$db"
  then
    echo "`date '+%Y-%m-%d %H:%M:%S'` $db full backup failed, proceeding"
    if [ -z "$failed_full" ]
    then
      failed_full="$db"
    else
      failed_full="$failed_full $db"
    fi
  else
    nfull=$((nfull+1))
  fi
done
exists=$(db.sh psql postgres -X -v ON_ERROR_STOP=1 -tAc "select 1 from pg_database where datname = 'affiliations'") || {
  echo "Cannot check whether the shared affiliations database exists" >&2
  exit 1
}
if [ "$exists" = "1" ]
then
  if [ -z "$SKIP_FLAGS" ] && ! wait_idle "affiliations" "full backup"
  then
    skipped="${skipped:+$skipped }affiliations"
  else
    echo "`date '+%Y-%m-%d %H:%M:%S'` full affiliations (shared actors/affiliations data)"
    if ! dump_full "affiliations"
    then
      echo "`date '+%Y-%m-%d %H:%M:%S'` affiliations full backup failed, proceeding"
      if [ -z "$failed_full" ]
      then
        failed_full="affiliations"
      else
        failed_full="$failed_full affiliations"
      fi
    else
      nfull=$((nfull+1))
    fi
  fi
fi
if [ ! -z "$skipped" ]
then
  echo "`date '+%Y-%m-%d %H:%M:%S'` Incomplete backups (busy wait limit or failed activity check): $skipped"
fi
if [ ! -z "$failed" ]
then
  echo "`date '+%Y-%m-%d %H:%M:%S'` Failed artificial events backups: $failed"
else
  echo "`date '+%Y-%m-%d %H:%M:%S'` All attempted artificial events backups OK"
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
if [ ! -z "$skipped$failed$failed_full" ]
then
  exit 1
fi
