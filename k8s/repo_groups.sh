#!/bin/bash
# USE_FLAGS=1 (will check devstats runnign flag and abort when set, then it will clear provisioned flag for the time of adding new metric and then set it)
# REPOS=1 (run get_repos in addition to repo groups setup)
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

if [ ! -z "$REPOS" ]
then
  GHA2DB_LOCAL=1 GHA2DB_PROCESS_REPOS=1 get_repos
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
  echo "Project: $proj, PDB: $db"
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/wait_flag.sh "$db" devstats_running 0 30 || exit 3
    ./devel/clear_flag.sh "$db" provisioned || exit 4
  fi
  GHA2DB_PROJECT=$proj PG_DB=$db ./shared/setup_repo_groups.sh || exit 3
  if [ ! -z "$REPOS" ]
  then
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/get_repos.sh || exit 4
  fi
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh "$db" provisioned || exit 6
  fi
done
echo 'OK'
