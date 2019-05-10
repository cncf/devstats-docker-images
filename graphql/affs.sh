#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="graphql/projects.yaml"
export LIST_FN_PREFIX="graphql/all_"

. ./devel/all_projs.sh || exit 2
for proj in $all
do
  db=$proj
  ./devel/check_flag.sh "$db" devstats_running 0 || exit 3
  ./devel/clear_flag.sh "$db" provisioned || exit 4
  GHA2DB_PROJECT=$proj PG_DB=$db ./shared/all_affs.sh || exit 5
  ./devel/set_flag.sh "$db" provisioned || exit 6
done

echo 'All affiliations updated'
