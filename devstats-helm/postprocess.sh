#!/bin/bash
# Bounded rebuild of the generated tables (gha_texts, gha_issues_events_labels, gha_issues_pull_requests)
# for a created_at/event-time window. Run this after a dated ghapi.sh/API backfill, or as a targeted repair
# of ONLY those three generated tables - the normal hourly postprocess uses a max(event_id) watermark and
# would otherwise skip older-dated rows arriving late.
# NOTE: after a raw `gha2db` re-ingest, run normal full `structure` FIRST (a raw reingest can affect more
# postprocess than these three tables); this helper only rebuilds the three generated tables.
#
# It calls `structure`, which - when GHA2DB_POSTPROCESS_FROM/TO are set - runs ONLY the *_range.sql rebuild
# scripts for the window (it does NOT touch the hourly scripts and skips the full Tools refresh). For a full
# rebuild instead, truncate the three tables and run `structure` with NO range (see runbook).
#
# Range from GHA2DB_POSTPROCESS_FROM/TO, falling back to DTFROM/DTTO (helm ghapiDtFrom/ghapiDtTo).
# Scope to one project with ONLY=<project> (honored by devel/all_projs.sh), e.g. ONLY=kubernetes.
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

export GHA2DB_POSTPROCESS_FROM="${GHA2DB_POSTPROCESS_FROM:-$DTFROM}"
export GHA2DB_POSTPROCESS_TO="${GHA2DB_POSTPROCESS_TO:-$DTTO}"
if [ -z "$GHA2DB_POSTPROCESS_FROM" ]
then
  echo "$0: set GHA2DB_POSTPROCESS_FROM (or ghapiDtFrom/DTFROM) to the backfilled range start."
  echo "$0: for a full rebuild, truncate the generated tables and run 'structure' without a range instead."
  exit 1
fi

# The upper bound is EXCLUSIVE (created_at < TO). If TO is a bare date (YYYY-MM-DD) it would parse as
# 00:00:00 and drop that whole day, so normalize a date-only TO to the next day 00:00:00.
if [[ "$GHA2DB_POSTPROCESS_TO" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
then
  # GNU date first, busybox fallback; fail loudly rather than silently widening the range
  nxt="$(date -u -d "$GHA2DB_POSTPROCESS_TO +1 day" '+%Y-%m-%d 00:00:00' 2>/dev/null)"
  if [ -z "$nxt" ]
  then
    epoch="$(date -u -D '%Y-%m-%d' -d "$GHA2DB_POSTPROCESS_TO" +%s 2>/dev/null)"
    [ -n "$epoch" ] && nxt="$(date -u -d "@$((epoch + 86400))" '+%Y-%m-%d 00:00:00' 2>/dev/null)"
  fi
  if [ -z "$nxt" ]
  then
    echo "$0: cannot normalize date-only GHA2DB_POSTPROCESS_TO='$GHA2DB_POSTPROCESS_TO', pass a full 'YYYY-MM-DD HH:MM:SS' timestamp"
    exit 1
  fi
  GHA2DB_POSTPROCESS_TO="$nxt"
fi
# No explicit upper bound at all -> rebuild everything from FROM onward.
if [ -z "$GHA2DB_POSTPROCESS_TO" ]
then
  export GHA2DB_POSTPROCESS_TO='2100-01-01 00:00:00'
fi
export GHA2DB_POSTPROCESS_TO

export GHA2DB_PROJECTS_YAML="devstats-helm/projects.yaml"
export LIST_FN_PREFIX="devstats-helm/all_"

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
  exists=$(./devel/db.sh psql "$db" -tAc "select 1 from information_schema.tables where table_name = 'gha_texts' limit 1" 2>/dev/null)
  if [ -z "$exists" ]
  then
    echo "Project: $proj, PDB: $db - database or gha_texts table missing (not provisioned yet?), skipping"
    continue
  fi
  echo "Project: $proj, PDB: $db, postprocess rebuild range: [$GHA2DB_POSTPROCESS_FROM, $GHA2DB_POSTPROCESS_TO)"
  GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db GHA2DB_SKIPTABLE=1 GHA2DB_MGETC=y structure || exit 3
  # Refresh planner stats after the bounded delete/insert (matters for large backfill windows).
  ./devel/db.sh psql "$db" -c 'analyze gha_texts; analyze gha_issues_events_labels; analyze gha_issues_pull_requests;' || exit 4
done
echo 'OK'
