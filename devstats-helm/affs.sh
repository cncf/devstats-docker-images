#!/bin/bash
# USE_FLAGS=1 (will check devstats running flag and abort when set, then it will clear provisioned flag for the time of adding new metric and then set it)
# SKIPTEMP=1 (skip regenerating using temporary database)
# GET_AFFS_FILES=1 (will fetch affiliations JSON and company acquisitions YAML from cncf/devstats repo)
# GHA2DB_CHECK_IMPORTED_SHA=1 (will check if given file was already imported)
# SKIP_IMP_AFFS=percent - % chance to skip import_affs.sh phase, "0" to force always run
# SKIP_UPD_AFFS=percent - % chance to skip update_affs.sh phase (default 33%), "0" to force always run
# GIANT=lock|wait|'' lock giant lock or only wait for giant lock or do not use giant lock
# SKIP_AFFS_LOCK=1 (will skip affs_lock flag - it prevents multiple affiliations import at the same time)
# AFFS_LOCK_DB=dbname - use different DB for dealing with affiliations lock (default is devstats).
# NO_DURABLE=1 - do not use durable flags
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi
echo "Initial import/update TSDB: '${SKIP_IMP_AFFS}'/'${SKIP_UPD_AFFS}'"
affsLockDB=devstats
if [ ! -z "$AFFS_LOCK_DB" ]
then
  affsLockDB="$AFFS_LOCK_DB"
fi
if ( [ -z "$NO_DURABLE" ] || [ "$NO_DURABLE" = "0" ] || [ "$NO_DURABLE" = "false" ] )
then
  export DURABLE=1
fi
if [ -z "$GHA2DB_MAX_RUN_DURATION" ]
then
  export GHA2DB_MAX_RUN_DURATION="annotations:1h:102,calc_metric:24h:102,columns:1h:102,get_repos:24h:102,gha2db:24h:102,ghapi2db:24h:102,import_affs:8h:102,structure:2h:102,tags:1h:102"
  echo "using the default max run duration setting: '$GHA2DB_MAX_RUN_DURATION'"
fi
if ( [ ! -z "$USE_FLAGS" ] && [ ! -z "$GIANT" ] )
then
  if ( [ -z "$SKIP_AFFS_LOCK" ] || [ "$SKIP_AFFS_LOCK" = "0" ] || [ "$SKIP_AFFS_LOCK" = "false" ] )
  then
    ./devel/set_flag.sh devstats "affs_lock_${ONLY}" || exit 15
  fi
  ./devel/wait_flag.sh devstats giant_lock 0 60 || exit 11
  if [ "$GIANT" = "lock" ]
  then
    ./devel/set_flag.sh devstats giant_lock || exit 12
  fi
  if ( [ -z "$SKIP_AFFS_LOCK" ] || [ "$SKIP_AFFS_LOCK" = "0" ] || [ "$SKIP_AFFS_LOCK" = "false" ] )
  then
    ./devel/wait_flag.sh "$affsLockDB" affs_lock 0 90 || exit 13
    ./devel/set_flag.sh "$affsLockDB" affs_lock || exit 14
  fi
fi
export NO_FATAL_DELAY=1
function set_flag {
  err="$?"
  if [ ! -z "$USE_FLAGS" ]
  then
    echo "Exit handler, final status is '$err'"
    user=gha_admin
    if [ ! -z "${PG_USER}" ]
    then
      user="${PG_USER}"
    fi
    for proj in $all
    do
      db=$proj
      if [ "$proj" = "kubernetes" ]
      then
        db="gha"
      elif [ "$proj" = "all" ]
      then
        db="allprj"
      fi
      ./devel/set_flag.sh "$db" provisioned
      if [ ! "$err" = "0" ]
      then
        PG_USER="$user" ./devel/db.sh psql "$db" -c "delete from gha_imported_shas where sha in ('$sum1', '$sum2')"
      fi
    done
  fi
  if ( [ -z "$SKIP_AFFS_LOCK" ] || [ "$SKIP_AFFS_LOCK" = "0" ] || [ "$SKIP_AFFS_LOCK" = "false" ] )
  then
    ./devel/clear_flag.sh "$affsLockDB" affs_lock
  fi
  if [ "$GIANT" = "lock" ]
  then
    ./devel/clear_flag.sh devstats giant_lock
  fi
  if ( [ -z "$SKIP_AFFS_LOCK" ] || [ "$SKIP_AFFS_LOCK" = "0" ] || [ "$SKIP_AFFS_LOCK" = "false" ] )
  then
    ./devel/clear_flag.sh devstats "affs_lock_${ONLY}"
  fi
}

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"
export GHA2DB_GHAPIFORCELICENSES=1
export GHA2DB_GHAPIFORCELANGS=1

if [ ! -z "$GET_AFFS_FILES" ]
then
  if [ ! -z "$GHA2DB_AFFILIATIONS_JSON" ]
  then
    wget https://github.com/cncf/devstats/raw/master/github_users.json -O "$GHA2DB_AFFILIATIONS_JSON" || exit 7
    sum1=`sha256sum "$GHA2DB_AFFILIATIONS_JSON" | awk '{print $1}'`
  else
    wget https://github.com/cncf/devstats/raw/master/github_users.json -O github_users.json || exit 8
    sum1=`sha256sum github_users.json | awk '{print $1}'`
  fi
  if [ ! -z "$GHA2DB_COMPANY_ACQ_YAML" ]
  then
    wget https://github.com/cncf/devstats/raw/master/companies.yaml -O "$GHA2DB_COMPANY_ACQ_YAML" || exit 9
    sum2=`sha256sum "$GHA2DB_COMPANY_ACQ_YAML" | awk '{print $1}'`
  else
    wget https://github.com/cncf/devstats/raw/master/companies.yaml -O companies.yaml || exit 10
    sum2=`sha256sum companies.yaml | awk '{print $1}'`
  fi
else
  sum1=`sha256sum github_users.json | awk '{print $1}'`
  sum2=`sha256sum companies.yaml | awk '{print $1}'`
fi

echo "Importing SHA pair ('$sum1', '$sum2')"

trap set_flag EXIT

. ./devel/all_projs.sh || exit 2
for proj in $all
do
  db=$proj
  if [ "$proj" = "kubernetes" ]
  then
    db="gha"
  elif [ "$proj" = "all" ]
  then
    db="allprj"
  fi
  if [ ! -z "$GHA2DB_CHECK_IMPORTED_SHA" ]
  then
    GHA2DB_PROJECT=$proj PG_DB=$db GHA2DB_LOCAL=1 GHA2DB_ONLY_CHECK_IMPORTED_SHA=1 import_affs
    code="$?"
    if [ ! "$code" = "0" ]
    then
      if [ "$code" = "3" ]
      then
        echo "Project $proj, current affiliations files are already imported"
        continue
      else
        echo "Project $proj error, exiting"
        exit $code
      fi
    else
      echo "Project $proj affiliations not imported yet, proceeding"
    fi
  fi
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/wait_flag.sh "$db" devstats_running 0 30 || exit 3
    ./devel/clear_flag.sh "$db" provisioned || exit 4
  fi
  GHA2DB_PROJECT=$proj PG_DB=$db ./shared/all_affs.sh || exit 5
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh "$db" provisioned || exit 6
  fi
done

echo 'All affiliations updated'
