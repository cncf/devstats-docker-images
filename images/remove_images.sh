#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi
# RUST=1: remove the "-rust" images (see images/build_images.sh) instead of the regular ones.
SUFFIX=""
if [ ! -z "${RUST}" ]
then
  SUFFIX="-rust"
  SKIP_GRAFANA=1
  SKIP_PATRONI=1
  SKIP_STATIC_NOBINS=1
fi
if [ -z "$SKIP_FULL" ]
then
  [ -z "${SUFFIX}" ] && docker image rm -f "${DOCKER_USER}/devstats"
  docker image rm -f "${DOCKER_USER}/devstats-test${SUFFIX}"
  docker image rm -f "${DOCKER_USER}/devstats-prod${SUFFIX}"
fi
if [ -z "$SKIP_MIN" ]
then
  [ -z "${SUFFIX}" ] && docker image rm -f "${DOCKER_USER}/devstats-minimal"
  docker image rm -f "${DOCKER_USER}/devstats-minimal-test${SUFFIX}"
  docker image rm -f "${DOCKER_USER}/devstats-minimal-prod${SUFFIX}"
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
  docker image rm -f "${DOCKER_USER}/devstats-patroni-18-hll"
fi
if [ -z "$SKIP_TESTS" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-tests${SUFFIX}"
fi
if [ -z "$SKIP_STATIC" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-static-test${SUFFIX}"
  docker image rm -f "${DOCKER_USER}/devstats-static-prod${SUFFIX}"
  if [ -z "$SKIP_STATIC_NOBINS" ]
  then
    docker image rm -f "${DOCKER_USER}/backups-page"
    docker image rm -f "${DOCKER_USER}/devstats-static-cdf"
    docker image rm -f "${DOCKER_USER}/devstats-static-graphql"
    docker image rm -f "${DOCKER_USER}/devstats-static-default"
  fi
fi
if [ -z "$SKIP_REPORTS" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-reports${SUFFIX}"
fi
if [ -z "$SKIP_API" ]
then
  docker image rm -f "${DOCKER_USER}/devstats-api-test${SUFFIX}"
  docker image rm -f "${DOCKER_USER}/devstats-api-prod${SUFFIX}"
fi
if [ ! -z "${SUFFIX}" ]
then
  # intermediate image holding the compiled Rust binaries (images/Dockerfile.rust-bins)
  docker image rm -f "${DOCKER_USER}/devstats-rust-bins"
fi
if [ -z "$SKIP_PRUNE" ]
then
  docker system prune -f
fi
