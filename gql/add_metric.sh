#!/bin/bash
# USE_FLAGS=1 (will check devstats runnign flag and abort when set, then it will clear provisioned flag for the time of adding new metric and then set it)
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="gql/projects.yaml"
export LIST_FN_PREFIX="gql/all_"

. ./devel/all_projs.sh || exit 2
for proj in $all
do
  db=$proj
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/check_flag.sh "$db" devstats_running 0 || exit 3
    ./devel/clear_flag.sh "$db" provisioned || exit 4
  fi
  GHA2DB_PROJECT=$proj PG_DB=$db ./devel/add_single_metric.sh || exit 5
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh "$db" provisioned || exit 6
  fi
done

echo 'OK'
