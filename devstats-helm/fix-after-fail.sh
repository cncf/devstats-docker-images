#!/bin/bash
if [ -z "$1" ]
then
  echo "Usage: $0 <project>"
  exit 1
fi
echo -n "Confirm that you updated $1/psql.sh or CTRL^C: "
read
exec > >(tee 1)
exec 2> >(tee 2)
echo "You can track progress via 'tail -f ?'"
WAITBOOT=1 ORGNAME="-" PORT="-" ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 PDB=1 TSDB=1 GHA2DB_MGETC=y ./$1/psql.sh && \
  WAITBOOT=1 ORGNAME="-" PORT="-" ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 PDB=1 TSDB=1 GHA2DB_MGETC=y ./devel/ro_user_grants.sh "$1" && \
  WAITBOOT=1 ORGNAME="-" PORT="-" ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 PDB=1 TSDB=1 GHA2DB_MGETC=y ./devel/psql_user_grants.sh "devstats_team" "$1" && \
  GHA2DB_ALLOW_METRIC_FAIL=1 WAITBOOT=1 ./devstats-helm/deploy_all.sh
