#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"
export GHA2DB_GHAPISKIP=''
export GHA2DB_GHAPISKIPEVENTS=''
# export GHA2DB_GHAPISKIPISSUES=1
# export GHA2DB_GHAPISKIPPRS=1
# export GHA2DB_GHAPISKIPCOMMENTS=1
# export GHA2DB_GHAPISKIPREVIEWS=1
# export GHA2DB_GHAPISKIPFORKS=1
# export GHA2DB_GHAPISKIPRELEASES=1
# export GHA2DB_GHAPISKIPSTARS=1
# export GHA2DB_GHAPIALLOWINSERTFAIL=1
export GHA2DB_GHAPISKIPCOMMITS=1
export GHA2DB_GHAPISKIPLICENSES=1
export GHA2DB_GHAPISKIPLANGS=1
export GHA2DB_GITHUB_DEBUG=1

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
# Self-correct after a dated backfill: rebuild the generated tables (gha_texts, gha_issues_events_labels,
# gha_issues_pull_requests) for the same window. The hourly max(event_id) postprocess would otherwise skip
# older-dated rows that this backfill just inserted. No DTFROM (plain recent sync) => skipped.
# Set GHA2DB_GHAPI_SKIP_POSTPROCESS=1 to opt out (emergency/performance).
if [ -n "$DTFROM" ] && [ -z "$GHA2DB_GHAPI_SKIP_POSTPROCESS" ]
then
  echo "Running bounded generated-table postprocess for ghapi backfill range [$DTFROM, $DTTO)"
  ./devstats-helm/postprocess.sh || exit 4
fi
echo 'OK'
