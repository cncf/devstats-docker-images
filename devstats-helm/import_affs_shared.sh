#!/bin/bash
# GET_AFFS_FILES=1 (fetch github_users.json and companies.yaml from cncf/devstats repo)
# GHA2DB_CHECK_IMPORTED_SHA=1 (skip clean+import when the files were already imported)
# GIANT=lock|wait|'' (giant lock handling, same as affs.sh)
# SKIP_AFFS_LOCK=1 (skip the affs_lock flag)
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi
if [ -z "$GHA2DB_AFFILIATIONS_DB" ]
then
  export GHA2DB_AFFILIATIONS_DB=affiliations
fi
adb="${GHA2DB_AFFILIATIONS_DB}"
affsLockDB=devstats
lockOwner="${HOSTNAME}-$$-${RANDOM}"
export NO_FATAL_DELAY=1
if [ -z "$GHA2DB_PROJECT" ]
then
  export GHA2DB_PROJECT=shared
fi
if [ -z "$GHA2DB_MAX_RUN_DURATION" ]
then
  export GHA2DB_MAX_RUN_DURATION="import_affs:8h:102,runq:2h:102"
fi

function clear_flags {
  err="$?"
  echo "Exit handler, final status is '$err'"
  if ( [ -z "$SKIP_AFFS_LOCK" ] || [ "$SKIP_AFFS_LOCK" = "0" ] || [ "$SKIP_AFFS_LOCK" = "false" ] )
  then
    ./devel/unlock_shared.sh "$affsLockDB" affs_lock "$lockOwner"
  fi
  if [ "$GIANT" = "lock" ]
  then
    ./devel/clear_flag.sh devstats giant_lock
  fi
}

if [ ! -z "$GIANT" ]
then
  ./devel/wait_flag.sh devstats giant_lock 0 60 || exit 4
  if [ "$GIANT" = "lock" ]
  then
    ./devel/set_flag.sh devstats giant_lock || exit 5
  fi
fi
if ( [ -z "$SKIP_AFFS_LOCK" ] || [ "$SKIP_AFFS_LOCK" = "0" ] || [ "$SKIP_AFFS_LOCK" = "false" ] )
then
  ./devel/lock_shared.sh "$affsLockDB" affs_lock "$lockOwner" || exit 6
fi
trap clear_flags EXIT

if [ ! -z "$GET_AFFS_FILES" ]
then
  wget https://github.com/cncf/devstats/raw/master/github_users.json -O github_users.json || exit 2
  wget https://github.com/cncf/devstats/raw/master/companies.yaml -O companies.yaml || exit 3
fi

newsha=1
if [ ! -z "$GHA2DB_CHECK_IMPORTED_SHA" ]
then
  PG_DB="$adb" GHA2DB_LOCAL=1 GHA2DB_ONLY_CHECK_IMPORTED_SHA=1 import_affs
  code="$?"
  if [ "$code" = "3" ]
  then
    echo "Affiliations source files already imported"
    newsha=0
  elif [ ! "$code" = "0" ]
  then
    echo "Error checking imported SHA: $code"
    exit 8
  fi
fi

if [ "$newsha" = "1" ]
then
  export LIST_FN_PREFIX="devstats-helm/all_"
  . ./devel/all_dbs.sh || exit 15
  for db in $all
  do
    echo "Marking commit-used actor names: $db"
    PG_DB="$db" GHA2DB_LOCAL=1 runq util_sql/mark_used_names_shared.sql || exit 16
  done
  echo "Importing new affiliations source files into the shared '$adb' DB"
  PG_DB="$adb" GHA2DB_LOCAL=1 runq scripts/clean_affiliations.sql || exit 9
  PG_DB="$adb" GHA2DB_LOCAL=1 GHA2DB_CHECK_IMPORTED_SHA=1 import_affs || exit 10
else
  echo "Reconciliation import pass (no clean) into the shared '$adb' DB"
  PG_DB="$adb" GHA2DB_LOCAL=1 GHA2DB_CHECK_IMPORTED_SHA='' import_affs || exit 10
fi

echo "Reconciling shared '$adb' DB (multi-ID affiliations, country names, bot logins, identity maps)"
PG_DB="$adb" GHA2DB_LOCAL=1 runq util_sql/update_affiliations.sql || exit 11
PG_DB="$adb" GHA2DB_LOCAL=1 runq util_sql/update_country_names.sql || exit 12
PG_DB="$adb" GHA2DB_LOCAL=1 runq util_sql/exclude_bots_table_insert.sql || exit 13
PG_DB="$adb" GHA2DB_LOCAL=1 runq util_sql/shared_maps.sql || exit 14
echo "Shared affiliations import/reconciliation OK"
