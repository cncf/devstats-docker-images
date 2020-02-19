#!/bin/bash
# ONLY_GHA=1 - assume that DB backup has *only* gha data, so all other stuff must be generated
wget "${RESTORE_FROM}/${PROJDB}.dump" || exit 1
./devel/drop_psql_db.sh "$PROJDB" || exit 2
db.sh psql postgres -c "create database $PROJDB" || exit 3
db.sh psql postgres -c "grant all privileges on database \"$PROJDB\" to gha_admin" || exit 4
db.sh psql "$PROJDB" -c "create extension if not exists pgcrypto" || exit 5
db.sh pg_restore -d "$PROJDB" "$PROJDB.dump" || echo "returned exit code, but attempt to continue"
rm -f "${PROJDB}.dump" || exit 6
db.sh psql "$PROJDB" -c "delete from gha_vars" || exit 7
if [ ! -z "$ONLY_GHA" ]
then
  GHA2DB_PROJECT=$PROJ PG_DB=$PROJDB ./shared/setup_repo_groups.sh || exit 8
  GHA2DB_PROJECT=$PROJ PG_DB=$PROJDB ./shared/setup_scripts.sh || exit 9
  GHA2DB_PROJECT=$PROJ PG_DB=$PROJDB ./shared/import_affs.sh || exit 10
fi
GHA2DB_PROJECT=$PROJ PG_DB=$PROJDB ./shared/get_repos.sh || exit 11
GHA2DB_PROJECT="$PROJ" PG_DB="$PROJDB" GHA2DB_LOCAL=1 vars || exit 12
GHA2DB_PROJECT="$PROJ" PG_DB="$PROJDB" GHA2DB_LOCAL=1 GHA2DB_VARS_FN_YAML="sync_vars.yaml" vars || exit 13
if [ ! -z "$ONLY_GHA" ]
then
  GHA2DB_PROJECT=$PROJ PG_DB=$PROJDB GHA2DB_LOCAL=1 tags || exit 14
  GHA2DB_PROJECT=$PROJ PG_DB=$PROJDB GHA2DB_LOCAL=1 annotations || exit 15
fi
GHA2DB_PROJECT=$PROJ PG_DB=$PROJDB GHA2DB_LOCAL=1 gha2db_sync || exit 16
./devel/set_flag.sh "$PROJDB" provisioned || exit 17
./devel/clear_flag.sh "$PROJDB" devstats_running || exit 18
echo 'OK'
