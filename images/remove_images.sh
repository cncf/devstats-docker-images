#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi
if [ -z "$SKIP_FULL" ]
then
  docker image rm -f "${DOCKER_USER}/devstats"
  docker image rm -f "${DOCKER_USER}/devstats-test"
  docker image rm -f "${DOCKER_USER}/devstats-prod"
fi
if [ -z "$SKIP_MIN" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-minimal"
  docker image rm -f "${DOCKER_USER}/devstats-minimal-test"
  docker image rm -f "${DOCKER_USER}/devstats-minimal-prod"
fi
if [ -z "$SKIP_GRAFANA" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-grafana"
fi
if [ -z "$SKIP_PATRONI" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-patroni"
  docker image rm -f "${DOCKER_USER}/devstats-patroni-new"
  docker image rm -f "${DOCKER_USER}/devstats-patroni-13"
  docker image rm -f "${DOCKER_USER}/devstats-patroni-hll-13"
  docker image rm -f "${DOCKER_USER}/devstats-patroni-18"
fi
if [ -z "$SKIP_TESTS" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-tests"
fi
if [ -z "$SKIP_STATIC" ]
then
  docker image rm -f "${DOCKER_USER}/backups-page"
  docker image rm -f "${DOCKER_USER}/devstats-static-test"
  docker image rm -f "${DOCKER_USER}/devstats-static-prod"
  docker image rm -f "${DOCKER_USER}/devstats-static-cdf"
  docker image rm -f "${DOCKER_USER}/devstats-static-graphql"
  docker image rm -f "${DOCKER_USER}/devstats-static-default"
fi
if [ -z "$SKIP_REPORTS" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-reports"
fi
if [ -z "$SKIP_API" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-api-test"
  docker image rm -f "${DOCKER_USER}/devstats-api-prod"
fi
if [ -z "$SKIP_PRUNE" ]
then
  docker system prune -f
fi
