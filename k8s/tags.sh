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

if [ ! -z "$GHA2DB_USE_ES" ]
then
  export GHA2DB_ES_URL="${ES_PROTO}://${ES_HOST}:${ES_PORT}"
fi
export GHA2DB_PROJECTS_YAML="k8s/projects.yaml"
export LIST_FN_PREFIX="k8s/all_"

user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi

. ./devel/all_projs.sh || exit 4
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
    ./devel/wait_flag.sh "$db" devstats_running 0 30 || exit 5
    ./devel/clear_flag.sh "$db" provisioned || exit 6
  fi
  if [ -f "./$proj/tags.sh" ]
  then
    ./$proj/tags.sh || exit 7
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/tags.sh || exit 8
  fi
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh "$db" provisioned || exit 9
  fi
done

echo 'OK'
