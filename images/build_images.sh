#!/bin/bash
# DOCKER_USER=lukaszgryglicki SKIP_TEST=1 SKIP_PROD=1 SKIP_FULL=1 SKIP_MIN=1 SKIP_GRAFANA=1 SKIP_TESTS=1 SKIP_PATRONI=1 SKIP_STATIC=1 SKIP_REPORTS=1 SKIP_API=1 SKIP_PUSH=1 ./images/build_images.sh
# DOCKER_USER=lukaszgryglicki ./images/remove_images.sh
# SKIP_TEST=1 (skip test images)
# SKIP_PROD=1 (skip prod images)
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi

cwd="`pwd`"
cd ../devstats || exit 2
cd ../devstats-reports || exit 39
cd ../devstatscode || exit 3

make replacer sqlitedb runq api || exit 4
rm -f ../devstats-docker-images/devstatscode.tar ../devstats-docker-images/grafana-bins.tar ../devstats-docker-images/api-bins.tar 2>/dev/null
tar cf ../devstats-docker-images/devstatscode.tar cmd vendor *.go || exit 5
tar cf ../devstats-docker-images/grafana-bins.tar replacer sqlitedb runq || exit 6
tar cf ../devstats-docker-images/api-bins.tar api || exit 44

cd ../devstats-reports || exit 40
rm -f ../devstats-docker-images/devstats-reports.tar 2>/dev/null
tar cf ../devstats-docker-images/devstats-reports.tar sh sql affs contributors velocity || exit 41

cd ../devstats || exit 7
rm -f ../devstats-docker-images/index_*.html ../devstats-docker-images/devstats.tar ../devstats-docker-images/devstats-grafana.tar ../devstats-docker-images/*.svg 2>/dev/null
tar cf ../devstats-docker-images/devstats.tar hide git metrics cdf devel util_sql envoy all lfn shared iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord scripts partials docs cron zephyr linux sam azf riff fn openwhisk openfaas cii prestodb kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni jaeger notary tuf rook vitess nats opa spiffe spire cloudevents telepresence helm openmetrics harbor etcd tikv cortex buildpacks falco dragonfly virtualkubelet kubeedge brigade crio networkservicemesh openebs opentelemetry thanos flux intoto strimzi kubevirt longhorn chubaofs keda smi argo cncf opencontainers istio spinnaker knative tekton jenkins jenkinsx allcdf graphql graphqljs graphiql expressgraphql graphqlspec kubeflow hyperledger jsons/.keep util_sh projects.yaml companies.yaml skip_dates.yaml github_users.json || exit 8
tar cf ../devstats-docker-images/devstats-grafana.tar grafana/shared grafana/img/*.svg grafana/img/*.png grafana/*/change_title_and_icons.sh grafana/*/custom_sqlite.sql grafana/dashboards/*/*.json || exit 9
cp apache/www/index_*.html ../devstats-docker-images/ || exit 22
cp grafana/img/*.svg ../devstats-docker-images/ || exit 32

cd "$cwd" || exit 10
rm -f devstats-docker-images.tar api-config.tar 2>/dev/null
tar cf devstats-docker-images.tar k8s example gql devstats-helm patches images/Makefile.* || exit 11
tar cf api-config.tar devstats-helm/projects.yaml || exit 45

if [ -z "$SKIP_FULL" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker build -f ./images/Dockerfile.full.test -t "${DOCKER_USER}/devstats-test" . || exit 12
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker build -f ./images/Dockerfile.full.prod -t "${DOCKER_USER}/devstats-prod" . || exit 33
  fi
fi

if [ -z "$SKIP_MIN" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker build -f ./images/Dockerfile.minimal.test -t "${DOCKER_USER}/devstats-minimal-test" . || exit 13
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker build -f ./images/Dockerfile.minimal.prod -t "${DOCKER_USER}/devstats-minimal-prod" . || exit 35
  fi
fi

if [ -z "$SKIP_GRAFANA" ]
then
  docker build -f ./images/Dockerfile.grafana -t "${DOCKER_USER}/devstats-grafana" . || exit 14
fi

if [ -z "$SKIP_TESTS" ]
then
  docker build -f ./images/Dockerfile.tests -t "${DOCKER_USER}/devstats-tests" . || exit 15
fi

if [ -z "$SKIP_PATRONI" ]
then
  #docker build -f ./images/Dockerfile.patroni -t "${DOCKER_USER}/devstats-patroni" . || exit 16
  docker build -f ./images/Dockerfile.patroni -t "${DOCKER_USER}/devstats-patroni-new" . || exit 16
fi

if [ -z "$SKIP_STATIC" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker build -f ./images/Dockerfile.static.test -t "${DOCKER_USER}/devstats-static-test" . || exit 24
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker build -f ./images/Dockerfile.static.prod -t "${DOCKER_USER}/devstats-static-prod" . || exit 23
  fi
  docker build -f ./images/Dockerfile.static.cdf -t "${DOCKER_USER}/devstats-static-cdf" . || exit 25
  docker build -f ./images/Dockerfile.static.graphql -t "${DOCKER_USER}/devstats-static-graphql" . || exit 26
  docker build -f ./images/Dockerfile.static.default -t "${DOCKER_USER}/devstats-static-default" . || exit 27
  docker build -f ./images/Dockerfile.static.backups -t "${DOCKER_USER}/backups-page" . || exit 42
fi

if [ -z "$SKIP_REPORTS" ]
then
  docker build -f ./images/Dockerfile.reports -t "${DOCKER_USER}/devstats-reports" . || exit 37
fi

if [ -z "$SKIP_API" ]
then
  if [ -z "$SKIP_PROD" ]
  then
    docker build -f ./images/Dockerfile.api -t "${DOCKER_USER}/devstats-api-prod" . || exit 46
  fi
  if [ -z "$SKIP_TEST" ]
  then
    docker build -f ./images/Dockerfile.api -t "${DOCKER_USER}/devstats-api-test" . || exit 48
  fi
fi

rm -f devstats.tar devstatscode.tar devstats-grafana.tar devstats-docker-images.tar grafana-bins.tar api-bins.tar api-config.tar devstats-reports.tar index_*.html *.svg

if [ ! -z "$SKIP_PUSH" ]
then
  exit 0
fi

if [ -z "$SKIP_FULL" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker push "${DOCKER_USER}/devstats-test" || exit 17
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker push "${DOCKER_USER}/devstats-prod" || exit 34
  fi
fi

if [ -z "$SKIP_MIN" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker push "${DOCKER_USER}/devstats-minimal-test" || exit 18
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker push "${DOCKER_USER}/devstats-minimal-prod" || exit 36
  fi
fi

if [ -z "$SKIP_GRAFANA" ]
then
  docker push "${DOCKER_USER}/devstats-grafana" || exit 19
fi

if [ -z "$SKIP_TESTS" ]
then
  docker push "${DOCKER_USER}/devstats-tests" || exit 20
fi

if [ -z "$SKIP_PATRONI" ]
then
  #docker push "${DOCKER_USER}/devstats-patroni" || exit 21
  docker push "${DOCKER_USER}/devstats-patroni-new" || exit 21
fi

if [ -z "$SKIP_STATIC" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker push "${DOCKER_USER}/devstats-static-test" || exit 28
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker push "${DOCKER_USER}/devstats-static-prod" || exit 24
  fi
  docker push "${DOCKER_USER}/devstats-static-cdf" || exit 29
  docker push "${DOCKER_USER}/devstats-static-graphql" || exit 30
  docker push "${DOCKER_USER}/devstats-static-default" || exit 31
  docker push "${DOCKER_USER}/backups-page" || exit 43
fi

if [ -z "$SKIP_REPORTS" ]
then
  docker push "${DOCKER_USER}/devstats-reports" || exit 38
fi

if [ -z "$SKIP_API" ]
then
  if [ -z "$SKIP_PROD" ]
  then
    docker push "${DOCKER_USER}/devstats-api-prod" || exit 47
  fi
  if [ -z "$SKIP_TEST" ]
  then
    docker push "${DOCKER_USER}/devstats-api-test" || exit 49
  fi
fi

echo 'OK'
