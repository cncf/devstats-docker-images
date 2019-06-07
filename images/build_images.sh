#!/bin/bash
# SKIP_FULL=1 SKIP_MIN=1 SKIP_GRAFANA=1 SKIP_TEST=1 SKIP_PATRONI=1 SKIP_STATIC=1 SKIP_PUSH=1
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
rm -f ../devstats-docker-images/index_*.html ../devstats-docker-images/devstats.tar ../devstats-docker-images/devstats-grafana.tar ../devstats-docker-images/*.svg 2>/dev/null
tar cf ../devstats-docker-images/devstats.tar git metrics cdf devel util_sql envoy all lfn shared iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord scripts partials docs cron zephyr linux kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni jaeger notary tuf rook vitess nats opa spiffe spire cloudevents telepresence helm openmetrics harbor etcd tikv cortex buildpacks falco dragonfly virtualkubelet kubeedge brigade crio networkservicemesh openebs opentelemetry cncf opencontainers istio spinnaker knative tekton jenkins jenkinsx graphql graphqljs graphiql expressgraphql graphqlspec kubeflow jsons/.keep util_sh/setup_scripts.sh util_sh/make_binary_links.sh projects.yaml companies.yaml skip_dates.yaml github_users.json || exit 8
tar cf ../devstats-docker-images/devstats-grafana.tar grafana/shared grafana/img/*.svg grafana/img/*.png grafana/*/change_title_and_icons.sh grafana/*/custom_sqlite.sql grafana/dashboards/*/*.json || exit 9
cp apache/www/index_*.html ../devstats-docker-images/ || exit 22
cp grafana/img/*.svg ../devstats-docker-images/ || exit 32

cd "$cwd" || exit 10
rm -f devstats-docker-images.tar 2>/dev/null
tar cf devstats-docker-images.tar k8s example gql devstats-helm patches images/Makefile.* || exit 11

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
  #docker build -f ./images/Dockerfile.patroni -t "${DOCKER_USER}/devstats-patroni" . || exit 16
  docker build -f ./images/Dockerfile.patroni -t "${DOCKER_USER}/devstats-patroni-new" . || exit 16
fi

if [ -z "$SKIP_STATIC" ]
then
  docker build -f ./images/Dockerfile.static.prod -t "${DOCKER_USER}/devstats-static-prod" . || exit 23
  docker build -f ./images/Dockerfile.static.test -t "${DOCKER_USER}/devstats-static-test" . || exit 24
  docker build -f ./images/Dockerfile.static.cdf -t "${DOCKER_USER}/devstats-static-cdf" . || exit 25
  docker build -f ./images/Dockerfile.static.graphql -t "${DOCKER_USER}/devstats-static-graphql" . || exit 26
  docker build -f ./images/Dockerfile.static.default -t "${DOCKER_USER}/devstats-static-default" . || exit 27
fi

rm -f devstats.tar devstatscode.tar devstats-grafana.tar devstats-docker-images.tar grafana-bins.tar index_*.html *.svg

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
  #docker push "${DOCKER_USER}/devstats-patroni" || exit 21
  docker push "${DOCKER_USER}/devstats-patroni-new" || exit 21
fi

if [ -z "$SKIP_STATIC" ]
then
  docker push "${DOCKER_USER}/devstats-static-prod" || exit 24
  docker push "${DOCKER_USER}/devstats-static-test" || exit 28
  docker push "${DOCKER_USER}/devstats-static-cdf" || exit 29
  docker push "${DOCKER_USER}/devstats-static-graphql" || exit 30
  docker push "${DOCKER_USER}/devstats-static-default" || exit 31
fi

echo 'OK'
