#!/bin/bash
# USE_FLAGS=1 (will check devstats running flag and abort when set, then it will clear provisioned flag for the time of adding new metric and then set it)
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi
if [ -z "${GHA2DB_FORCE_PERIODS}" ]
then
  echo "You need to set GHA2DB_FORCE_PERIODS environment variable to run this script"
  exit 2
fi

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"

. ./devel/all_projs.sh || exit 3
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

  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/wait_flag.sh "$db" devstats_running 0 30 || exit 4
    ./devel/clear_flag.sh "$db" provisioned || exit 5
  fi

  GHA2DB_PROJECT=$proj PG_DB=$db ./util_sh/recalculate_periods.sh || exit 6

  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh "$db" provisioned || exit 7
  fi
done
echo 'OK'
