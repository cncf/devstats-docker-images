#!/bin/bash
# USE_FLAGS=1 (will check devstats runnign flag and abort when set, then it will clear provisioned flag for the time of adding new metric and then set it)
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

if ( [ -z "$ES_HOST" ] || [ -z "$ES_PORT" ] || [ -z "$ES_PROTO" ] )
then
  echo "$0: you need to set ES_PROTO, ES_HOST and ES_PORT to run this script"
  exit 2
fi

# export GHA2DB_USE_ES
# export GHA2DB_USE_ES_RAW
export GHA2DB_PROJECTS_YAML="k8s/projects.yaml"
export GHA2DB_ES_URL="${ES_PROTO}://${ES_HOST}:${ES_PORT}"
export LIST_FN_PREFIX="k8s/all_"

. ./devel/all_projs.sh || exit 3
for proj in $all
do
  db=$proj
  if [ "$db" = "kubernetes" ]
  then
    db="gha"
  elif [ "$db" = "all" ]
  then
    db="allprj"
  fi
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/check_flag.sh "$db" devstats_running 0 || exit 4
    ./devel/clear_flag.sh "$db" provisioned || exit 5
  fi
  GHA2DB_PROJECT=$proj PG_DB=$db ./devel/add_single_metric.sh || exit 6
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh "$db" provisioned || exit 7
  fi
done

echo 'OK'
