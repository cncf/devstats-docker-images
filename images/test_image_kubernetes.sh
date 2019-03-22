#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 2
fi
if [ -z "$1" ]
then
  echo "$0: you need to pass devstats image name as an agument, possible options are: devstats, devstats-minimal, devstats-grafana"
  exit 3
fi
command="$2"
if [ -z "${command}" ]
then
  export command=/bin/bash
fi
ts=`date +'%s%N'`
kubectl run -i --tty "${1}-test-${ts}" --restart=Never --rm --image="${DOCKER_USER}/$1" --command "$command"
