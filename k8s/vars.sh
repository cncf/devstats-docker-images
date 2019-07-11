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
. ./devel/all_projs.sh || exit 3
for proj in $all
do
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/wait_flag.sh "$db" devstats_running 0 || exit 4
    ./devel/clear_flag.sh "$db" provisioned || exit 5
  fi
  db=$proj
  if [ "$proj" = "kubernetes" ]
  then
    db="gha"
  elif [ "$proj" = "all" ]
  then
    db="allprj"
  fi
  echo "Project: $proj, PDB: $db"
  if [ -z "${SKIPDEL}" ]
  then
    PG_USER="${user}" ./devel/db.sh psql "$db" -c "delete from gha_vars" || exit 1
  fi
  GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db vars || exit 2
  GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 3
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh "$db" provisioned || exit 10
  fi
done
echo 'OK'
