#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"

if [ ! -z "$PROJDB" ]
then
  export ONLY="$PROJDB"
fi

. ./devel/all_dbs.sh || exit 2
for db in $all
do
  ./devel/ro_user_grants.sh "$db" || exit 3
  ./devel/psql_user_grants.sh devstats_team "$db" || exit 4
done

echo 'OK'

