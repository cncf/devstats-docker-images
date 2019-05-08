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
tar cf ../devstats-docker-images/devstatscode.tar cmd vendor *.go || exit 5
tar cf ../devstats-docker-images/grafana-bins.tar replacer sqlitedb || exit 6

cd ../devstats || exit 7
rm -f ../devstats-docker-images/devstats.tar ../devstats-docker-images/devstats-grafana.tar 2>/dev/null
tar cf ../devstats-docker-images/devstats.tar git metrics cdf devel util_sql envoy all lfn shared iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord scripts partials docs cron zephyr linux kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni jaeger notary tuf rook vitess nats opa spiffe spire cloudevents telepresence helm openmetrics harbor etcd tikv cortex buildpacks falco dragonfly virtualkubelet kubeedge brigade crio networkservicemesh openebs opentelemetry cncf opencontainers istio spinnaker knative tekton jenkins jenkinsx jsons/.keep util_sh/make_binary_links.sh projects.yaml companies.yaml skip_dates.yaml github_users.json || exit 8
tar cf ../devstats-docker-images/devstats-grafana.tar grafana/shared grafana/img/*.svg grafana/img/*.png grafana/*/change_title_and_icons.sh grafana/*/custom_sqlite.sql grafana/dashboards/*/*.json || exit 9

cd "$cwd" || exit 10
rm -f devstats-docker-images.tar 2>/dev/null
tar cf devstats-docker-images.tar k8s example patches images/Makefile.* || exit 11

if [ -z "$SKIP_FULL" ]
then
  docker build -f ./images/Dockerfile.full -t "${DOCKER_USER}/devstats" . || exit 12
fi

if [ -z "$SKIP_MIN" ]
then
  docker build -f ./images/Dockerfile.minimal -t "${DOCKER_USER}/devstats-minimal" . || exit 13
fi

if [ -z "$SKIP_GRAFANA" ]
then
  docker build -f ./images/Dockerfile.grafana -t "${DOCKER_USER}/devstats-grafana" . || exit 14
fi

if [ -z "$SKIP_TEST" ]
then
  docker build -f ./images/Dockerfile.test -t "${DOCKER_USER}/devstats-test" . || exit 15
fi

if [ -z "$SKIP_PATRONI" ]
then
  docker build -f ./images/Dockerfile.patroni -t "${DOCKER_USER}/devstats-patroni" . || exit 16
fi

rm -f devstats.tar devstatscode.tar devstats-grafana.tar devstats-docker-images.tar grafana-bins.tar

if [ ! -z "$SKIP_PUSH" ]
then
  exit 0
fi

if [ -z "$SKIP_FULL" ]
then
  docker push "${DOCKER_USER}/devstats" || exit 17
fi

if [ -z "$SKIP_MIN" ]
then
  docker push "${DOCKER_USER}/devstats-minimal" || exit 18
fi

if [ -z "$SKIP_GRAFANA" ]
then
  docker push "${DOCKER_USER}/devstats-grafana" || exit 19
fi

if [ -z "$SKIP_TEST" ]
then
  docker push "${DOCKER_USER}/devstats-test" || exit 20
fi

if [ -z "$SKIP_PATRONI" ]
then
  docker push "${DOCKER_USER}/devstats-patroni" || exit 21
fi

echo 'OK'
