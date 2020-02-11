#!/bin/bash
# USE_FLAGS=1 (will check devstats running flag and abort when set, then it will clear provisioned flag for the time of adding new metric and then set it)
# GIANT=1 - use giant lock
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"
export GHA2DB_GHAPIFORCELICENSES=1
export GHA2DB_GHAPIFORCELANGS=1

if [ ! -z "$GIANT" ]
then
  ./devel/wait_flag.sh devstats giant_lock 0 20 || exit 8
  ./devel/set_flag.sh devstats giant_lock || exit 9
fi

function clear_flag {
  ./devel/clear_flag.sh devstats giant_lock
}

if [ ! -z "$GIANT" ]
then
  trap clear_flag EXIT
fi

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
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/wait_flag.sh "$db" devstats_running 0 || exit 3
    ./devel/clear_flag.sh "$db" provisioned || exit 4
  fi
  if [ -f "./$proj/reinit.sh" ]
  then
    ./$proj/reinit.sh || exit 5
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/reinit.sh || exit 6
  fi
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh "$db" provisioned || exit 7
  fi
done

echo 'TS data regenerated'
