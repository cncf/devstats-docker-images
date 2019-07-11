#!/bin/bash
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
export LIST_FN_PREFIX="k8s/all_"
if [ ! -z "$GHA2DB_USE_ES" ]
then
  export GHA2DB_ES_URL="${ES_PROTO}://${ES_HOST}:${ES_PORT}"
fi

# GHA2DB_LOCAL=1 GHA2DB_PROCESS_REPOS=1 get_repos
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

  ./devel/wait_flag.sh "$db" devstats_running 0 || exit 4
  ./devel/clear_flag.sh "$db" provisioned || exit 5
  GHA2DB_PROJECT=$proj PG_DB=$db ./shared/all_affs.sh || exit 6
  ./devel/set_flag.sh "$db" provisioned || exit 7
done

echo 'All affiliations updated'
