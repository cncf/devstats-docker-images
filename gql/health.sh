#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="gql/projects.yaml"
export LIST_FN_PREFIX="gql/all_"

ONLY='' ./devel/add_all_annotations.sh || exit 1
GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=metrics/all/health.yaml GHA2DB_TAGS_YAML=metrics/shared/empty.yaml GHA2DB_COLUMNS_YAML=metrics/shared/empty.yaml gha2db_sync || exit 2
GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 3
