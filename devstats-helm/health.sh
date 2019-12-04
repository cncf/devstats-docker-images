#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"
export GHA2DB_SKIP_METRICS=''
export GHA2DB_EXCLUDE_VARS=''

ONLY='' ./devel/add_all_annotations.sh
# should be run within devstats-provision-prestodb pod, after other project added their annotations or run devstats-helm/annotations.sh first.
if [ "$ONLY" = "prestodb" ]
then
  GHA2DB_PROJECT=prestodb PG_DB=prestodb GHA2DB_LOCAL=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=metrics/all/health.yaml GHA2DB_TAGS_YAML=metrics/shared/empty.yaml GHA2DB_COLUMNS_YAML=metrics/shared/empty.yaml gha2db_sync || exit 2
  GHA2DB_PROJECT=prestodb PG_DB=prestodb GHA2DB_LOCAL=1 GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 3
fi
# should be run within devstats-provision-graphql pod, after other project added their annotations or run devstats-helm/annotations.sh first.
if [ "$ONLY" = "graphql" ]
then
  GHA2DB_PROJECT=graphql PG_DB=graphql GHA2DB_LOCAL=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=metrics/all/health.yaml GHA2DB_TAGS_YAML=metrics/shared/empty.yaml GHA2DB_COLUMNS_YAML=metrics/shared/empty.yaml gha2db_sync || exit 4
  GHA2DB_PROJECT=graphql PG_DB=graphql GHA2DB_LOCAL=1 GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 5
fi
# should be run within devstats-provision-allcdf pod, after other project added their annotations or run devstats-helm/annotations.sh first.
if [ "$ONLY" = "allcdf" ]
then
  GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=metrics/all/health.yaml GHA2DB_TAGS_YAML=metrics/shared/empty.yaml GHA2DB_COLUMNS_YAML=metrics/shared/empty.yaml gha2db_sync || exit 6
  GHA2DB_PROJECT=allcdf PG_DB=allcdf GHA2DB_LOCAL=1 GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 7
fi
# should be run within devstats-provision-all pod, after other project added their annotations or run devstats-helm/annotations.sh first.
if [ "$ONLY" = "all" ]
then
  GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=metrics/all/health.yaml GHA2DB_TAGS_YAML=metrics/shared/empty.yaml GHA2DB_COLUMNS_YAML=metrics/shared/empty.yaml gha2db_sync || exit 8
  GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 9
fi
