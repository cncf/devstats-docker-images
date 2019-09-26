#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] || [ -z "$PROJDB" ] )
then
  echo "$0: you need to set PROJDB, PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi
./devel/clear_flag.sh "$PROJDB" devstats_running || exit 1
./devel/set_flag.sh "$PROJDB" provisioned || exit 2
