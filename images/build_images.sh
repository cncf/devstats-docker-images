#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi

cwd="`pwd`"
cd ../devstats || exit 2
cd ../devstatscode || exit 3

make replacer sqlitedb || exit 4
rm -f ../devstats-docker-images/devstatscode.tar ../devstats-docker-images/grafana-bins.tar 2>/dev/null
tar cf ../devstats-docker-images/devstatscode.tar cmd vendor *.go
tar cf ../devstats-docker-images/grafana-bins.tar replacer sqlitedb

cd ../devstats || exit 5
rm -f ../devstats-docker-images/devstats.tar ../devstats-docker-images/devstats-grafana.tar 2>/dev/null
tar cf ../devstats-docker-images/devstats.tar git metrics cdf devel util_sql envoy all lfn shared iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord scripts partials docs cron zephyr linux kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni jaeger notary tuf rook vitess nats opa spiffe spire cloudevents telepresence helm openmetrics harbor etcd tikv cortex buildpacks falco dragonfly virtualkubelet kubeedge brigade crio cncf opencontainers istio spinnaker knative jsons/.keep util_sh/make_binary_links.sh projects.yaml companies.yaml skip_dates.yaml github_users.json
tar cf ../devstats-docker-images/devstats-grafana.tar grafana/shared grafana/img/*.svg grafana/img/*.png grafana/*/change_title_and_icons.sh grafana/*/custom_sqlite.sql grafana/dashboards/*/*.json

cd "$cwd" || exit 6
rm -f devstats-docker-images.tar 2>/dev/null
tar cf devstats-docker-images.tar k8s

if [ -z "$SKIP_FULL" ]
then
  docker build -f ./images/Dockerfile.full -t "${DOCKER_USER}/devstats" . || exit 7
fi

if [ -z "$SKIP_MIN" ]
then
  docker build -f ./images/Dockerfile.minimal -t "${DOCKER_USER}/devstats-minimal" . || exit 8
fi

if [ -z "$SKIP_GRAFANA" ]
then
  docker build -f ./images/Dockerfile.grafana -t "${DOCKER_USER}/devstats-grafana" . || exit 9
fi

rm -f devstats.tar devstatscode.tar devstats-grafana.tar devstats-docker-images.tar grafana-bins.tar
exit 1

if [ -z "$SKIP_FULL" ]
then
  docker push "${DOCKER_USER}/devstats"
fi

if [ -z "$SKIP_MIN" ]
then
  docker push "${DOCKER_USER}/devstats-minimal"
fi

if [ -z "$SKIP_GRAFANA" ]
then
  docker push "${DOCKER_USER}/devstats-grafana"
fi
