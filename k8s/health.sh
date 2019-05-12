#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="k8s/projects.yaml"
export GHA2DB_ES_URL="${ES_PROTO}://${ES_HOST}:${ES_PORT}"
export LIST_FN_PREFIX="k8s/all_"
export GHA2DB_SKIP_METRICS=''
export GHA2DB_EXCLUDE_VARS=''

ONLY='' ./devel/add_all_annotations.sh || exit 1
GHA2DB_PROJECT=graphql PG_DB=graphql GHA2DB_LOCAL=1 GHA2DB_GHAPISKIP=1 GHA2DB_GETREPOSSKIP=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_METRICS_YAML=metrics/all/health.yaml GHA2DB_TAGS_YAML=metrics/shared/empty.yaml GHA2DB_COLUMNS_YAML=metrics/shared/empty.yaml gha2db_sync || exit 2
GHA2DB_PROJECT=graphql PG_DB=graphql GHA2DB_LOCAL=1 GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 3
