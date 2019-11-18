#!/bin/bash
# USE_FLAGS=1 (will check devstats running flag and abort when set, then it will clear provisioned flag for the time of adding new metric and then set it)
# SKIPTEMP=1 (skip regenerating using temporary database)
# GET_AFFS_FILES=1 (will fetch affiliations JSON and company acquisitions YAML from cncf/devstats repo)
# GHA2DB_CHECK_IMPORTED_SHA=1 (will check if given file was already imported)
# SKIP_IMP_AFFS=1 skip import_affs.sh phase
# SKIP_UPD_AFFS=1 skip update_affs.sh phase
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

#if [ ! "$GHA2DB_DEBUG" = "0" ]
#then
#  exit 0
#fi

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"

if [ ! -z "$GET_AFFS_FILES" ]
then
  if [ ! -z "$GHA2DB_AFFILIATIONS_JSON" ]
  then
    wget https://github.com/cncf/devstats/raw/master/github_users.json -O "$GHA2DB_AFFILIATIONS_JSON" || exit 7
  else
    wget https://github.com/cncf/devstats/raw/master/github_users.json -O github_users.json || exit 8
  fi
  if [ ! -z "$GHA2DB_COMPANY_ACQ_YAML" ]
  then
    wget https://github.com/cncf/devstats/raw/master/companies.yaml -O "$GHA2DB_COMPANY_ACQ_YAML" || exit 9
  else
    wget https://github.com/cncf/devstats/raw/master/companies.yaml -O companies.yaml || exit 10
  fi
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
  if [ ! -z "$GHA2DB_CHECK_IMPORTED_SHA" ]
  then
    GHA2DB_PROJECT=$proj PG_DB=$db GHA2DB_LOCAL=1 GHA2DB_ONLY_CHECK_IMPORTED_SHA=1 import_affs
    code="$?"
    if [ ! "$code" = "0" ]
    then
      if [ "$code" = "3" ]
      then
        echo "Project $proj, current affiliations files are already imported"
        continue
      else
        echo "Project $proj error, exiting"
        exit $code
      fi
    else
      echo "Project $proj affiliations not imported yet, proceeding"
    fi
  fi
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/wait_flag.sh "$db" devstats_running 0 30 || exit 3
    ./devel/clear_flag.sh "$db" provisioned || exit 4
  fi
  GHA2DB_PROJECT=$proj PG_DB=$db ./shared/all_affs.sh || exit 5
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh "$db" provisioned || exit 6
  fi
done

echo 'All affiliations updated'
