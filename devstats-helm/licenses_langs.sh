#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"
export GHA2DB_GHAPIFORCELICENSES=1
export GHA2DB_GHAPIFORCELANGS=1
export GHA2DB_GHAPISKIPEVENTS=1
export GHA2DB_GHAPISKIPCOMMITS=1

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
  GHA2DB_PROJECT=$proj PG_DB=$db ghapi2db || exit 3
done
echo 'OK'
