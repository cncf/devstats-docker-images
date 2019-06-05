#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"

user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi
. ./devel/all_projs.sh || exit 3
for proj in $all
do
    db=$proj
    echo "Project: $proj, PDB: $db"
    if [ -z "${SKIPDEL}" ]
    then
      PG_USER="${user}" ./devel/db.sh psql "$db" -c "delete from gha_vars" || exit 1
    fi
    GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db vars || exit 2
    GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 3
done
echo 'OK'
