#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi
if [ -z "$SKIP_FULL" ]
then
  docker image rm -f "${DOCKER_USER}/devstats"
fi
if [ -z "$SKIP_MIN" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-minimal"
fi
if [ -z "$SKIP_GRAFANA" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-grafana"
fi
if [ -z "$SKIP_PATRONI" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-patroni"
fi
if [ -z "$SKIP_TEST" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-test"
fi
if [ -z "$SKIP_STATIC" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-static-test"
  docker image rm -f "${DOCKER_USER}/devstats-static-prod"
  docker image rm -f "${DOCKER_USER}/devstats-static-cdf"
  docker image rm -f "${DOCKER_USER}/devstats-static-graphql"
  docker image rm -f "${DOCKER_USER}/devstats-static-default"
fi
if [ -z "$SKIP_PRUNE" ]
then
  docker system prune -f
fi
