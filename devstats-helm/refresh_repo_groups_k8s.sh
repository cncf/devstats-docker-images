#!/bin/bash
# USE_FLAGS=1 (will check devstats running flag and abort when set, then it will clear provisioned flag for the time of refreshing repo groups metrics and then set it)
# Hardcoded to Kubernetes project (projects[0] in devstats-helm/values.yaml: proj=kubernetes, db=gha) - cannot be overridden.
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"
export GHA2DB_GHAPIFORCELICENSES=1
export GHA2DB_GHAPIFORCELANGS=1

if [ ! -z "$USE_FLAGS" ]
then
  ./devel/wait_flag.sh gha devstats_running 0 || exit 3
  ./devel/clear_flag.sh gha provisioned || exit 4
fi
GHA2DB_METRICS_YAML='./metrics/kubernetes/metrics_repo_groups.yaml' GHA2DB_TAGS_YAML='./metrics/kubernetes/tags_repo_groups.yaml' GHA2DB_COLUMNS_YAML='./metrics/kubernetes/columns_repo_groups.yaml' GHA2DB_PROJECT=kubernetes PG_DB=gha ./devel/add_single_metric.sh || exit 5
if [ ! -z "$USE_FLAGS" ]
then
  ./devel/set_flag.sh gha provisioned || exit 6
fi

echo 'OK'
