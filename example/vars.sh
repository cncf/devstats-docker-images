#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="example/projects.yaml"
export LIST_FN_PREFIX="example/all_"

user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi
. ./devel/all_projs.sh || exit 3
for proj in $all
do
    #./devel/check_flag.sh "$db" devstats_running 0 || exit 4
    #./devel/clear_flag.sh "$db" provisioned || exit 5
    db=$proj
    echo "Project: $proj, PDB: $db"
    if [ -z "${SKIPDEL}" ]
    then
      PG_USER="${user}" ./devel/db.sh psql "$db" -c "delete from gha_vars" || exit 1
    fi
    GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db vars || exit 2
    GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 3
    #./devel/set_flag.sh "$db" provisioned || exit 10
done
echo 'OK'
