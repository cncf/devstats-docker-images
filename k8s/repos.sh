#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] || [ -z "$PROJDB" ] )
then
  echo "$0: you need to set PROJDB, PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="k8s/projects.yaml"
export LIST_FN_PREFIX="k8s/all_"

./devel/check_flag.sh "$PROJDB" devstats_running 0 || exit 2
./devel/clear_flag.sh "$PROJDB" provisioned || exit 3
GHA2DB_LOCAL=1 GHA2DB_PROCESS_REPOS=1 get_repos || exit 4
./devel/set_flag.sh "$PROJDB" provisioned || exit 5
