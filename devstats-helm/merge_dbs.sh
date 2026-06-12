#!/bin/bash
# GHA2DB_INPUT_DBS="db1,db2" or "-all-"
# GHA2DB_OUTPUT_DB="allprj"
# ONLY_TABLES="table1,table2"       optional, takes precedence over SKIP_TABLES
# SKIP_TABLES="table1,table2"       optional
# IGNORE_NO_DB=1                    optional, merge_dbs allows it only in "-all-" mode
# SKIP_DBS="db1,db2"                optional, merge_dbs allows it only in "-all-" mode
# GHA2DB_LOCAL=1                    optional, useful in debug/provision pods
# MERGE_DT_FROM="YYYY-MM-DD"        optional, copies date-mapped tables starting at YYYY-MM-DD 00:00:00

if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

if [ -z "$GHA2DB_INPUT_DBS" ]
then
  echo "$0: you need to set GHA2DB_INPUT_DBS, for example 'hami,kagent' or '-all-'"
  exit 2
fi

if [ -z "$GHA2DB_OUTPUT_DB" ]
then
  echo "$0: you need to set GHA2DB_OUTPUT_DB, for example 'allprj'"
  exit 3
fi

if [ -z "$GHA2DB_PROJECTS_YAML" ]
then
  if [ -f "devstats-helm/projects.yaml" ]
  then
    export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
  elif [ -f "projects.yaml" ]
  then
    export GHA2DB_PROJECTS_YAML="projects.yaml"
  fi
fi

echo "merge_dbs configuration:"
echo "  GHA2DB_INPUT_DBS=${GHA2DB_INPUT_DBS}"
echo "  GHA2DB_OUTPUT_DB=${GHA2DB_OUTPUT_DB}"
echo "  ONLY_TABLES=${ONLY_TABLES}"
echo "  SKIP_TABLES=${SKIP_TABLES}"
echo "  SKIP_DBS=${SKIP_DBS}"
echo "  IGNORE_NO_DB=${IGNORE_NO_DB}"
echo "  GHA2DB_LOCAL=${GHA2DB_LOCAL}"
echo "  MERGE_DT_DROM=${MERGE_DT_DROM}"
echo "  GHA2DB_PROJECTS_YAML=${GHA2DB_PROJECTS_YAML}"

command -v merge_dbs >/dev/null 2>&1
if [ ! "$?" = "0" ]
then
  echo "$0: merge_dbs binary not found in PATH"
  exit 4
fi

merge_dbs || exit 5
echo 'OK'
