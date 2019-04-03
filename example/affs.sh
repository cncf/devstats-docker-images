#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="example/projects.yaml"
export LIST_FN_PREFIX="example/all_"

# GHA2DB_LOCAL=1 GHA2DB_PROCESS_REPOS=1 get_repos
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

  ./devel/check_flag.sh "$db" devstats_running 0 || exit 3
  ./devel/clear_flag.sh "$db" provisioned || exit 4

  if [ -f "./$proj/import_affs.sh" ]
  then
    ./$proj/import_affs.sh || exit 5
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/import_affs.sh || exit 6
  fi
  if [ -f "./$proj/update_affs.sh" ]
  then
    ./$proj/update_affs.sh || exit 7
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/update_affs.sh || exit 8
  fi

  ./devel/set_flag.sh "$db" provisioned || exit 9
done

echo 'All affiliations updated'
