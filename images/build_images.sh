#!/bin/bash
# DOCKER_USER=lukaszgryglicki SKIP_TEST=1 SKIP_PROD=1 SKIP_FULL=1 SKIP_MIN=1 SKIP_GRAFANA=1 SKIP_TESTS=1 SKIP_PATRONI=1 SKIP_STATIC=1 SKIP_REPORTS=1 SKIP_API=1 SKIP_PUSH=1 ./images/build_images.sh
# DOCKER_USER=lukaszgryglicki ./images/remove_images.sh
# SKIP_TEST=1 (skip test images)
# SKIP_PROD=1 (skip prod images)
# RUST=1 (build the images with the Rust port of the DevStats binaries - devstatscode/rust - instead of the Go ones)
#   RUST=1 DOCKER_USER=lukaszgryglicki SKIP_PATRONI=1 ./images/build_images.sh
#   Every image that contains at least one DevStats binary is built under an alternate name with the "-rust" suffix:
#   devstats-test-rust, devstats-prod-rust, devstats-minimal-test-rust, devstats-minimal-prod-rust, devstats-tests-rust,
#   devstats-static-test-rust, devstats-static-prod-rust, devstats-reports-rust, devstats-api-prod-rust, devstats-api-test-rust.
#   Images without DevStats binaries (grafana, patroni, static-cdf/graphql/default, backups-page) are not built in this mode,
#   and the regular (Go) images are never touched. Binaries are compiled inside Docker (images/Dockerfile.rust-bins,
#   rust:alpine -> static Linux musl executables; Docker with BuildKit is required) into ./rust-bins/, then shipped
#   via grafana-bins.tar, api-bins.tar (same Dockerfiles as the Go images) and devstats-bins.tar (images/Dockerfile.*.rust,
#   generated from the Go Dockerfiles by images/rust_dockerfile.sh; images/Makefile.*.rust lay them out).
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi

# Rust mode: "-rust" image name suffix, skip images that contain no DevStats binaries.
SUFFIX=""
if [ ! -z "${RUST}" ]
then
  SUFFIX="-rust"
  SKIP_GRAFANA=1
  SKIP_PATRONI=1
  SKIP_STATIC_NOBINS=1
  for f in images/Dockerfile.full.test images/Dockerfile.full.prod images/Dockerfile.minimal.test images/Dockerfile.minimal.prod
  do
    ./images/rust_dockerfile.sh "$f" > "${f}.rust" || exit 54
  done
fi

# IMAGE_TAG=xyz: build and push every image as name:xyz instead of the default tag (latest) - e.g. to try new images
# in the test namespace without touching the tags the production CronJobs pull:
#   IMAGE_TAG=go127 SKIP_PROD=1 SKIP_GRAFANA=1 SKIP_PATRONI=1 SKIP_REPORTS=1 DOCKER_USER=lukaszgryglicki ./images/build_images.sh
TAG=""
if [ ! -z "${IMAGE_TAG}" ]
then
  TAG=":${IMAGE_TAG}"
fi

cwd="`pwd`"
cd ../devstats || exit 2
cd ../devstats-reports || exit 39
cd ../velocity || exit 45
cd ../devstatscode || exit 3

rm -f ../devstats-docker-images/devstatscode.tar ../devstats-docker-images/devstatscode-rust.tar ../devstats-docker-images/devstats-bins.tar ../devstats-docker-images/grafana-bins.tar ../devstats-docker-images/api-bins.tar 2>/dev/null
if [ -z "${RUST}" ]
then
  make replacer sqlitedb runq api calc_metric || exit 4
  tar cf ../devstats-docker-images/devstatscode.tar cmd *.go || exit 5
  tar cf ../devstats-docker-images/grafana-bins.tar replacer sqlitedb runq || exit 6
  tar cf ../devstats-docker-images/api-bins.tar api calc_metric || exit 44
else
  # Rust sources (without build directories) -> compiled inside Docker to static Linux binaries in ./rust-bins/.
  tar --exclude='target' --exclude='rust/.cargo' -cf ../devstats-docker-images/devstatscode-rust.tar rust || exit 5
  rust_hash=$(git rev-parse HEAD 2>/dev/null || echo None)
  cd ../devstats-docker-images || exit 55
  rm -rf rust-bins
  docker build -f ./images/Dockerfile.rust-bins --build-arg "DEVSTATS_GIT_HASH=${rust_hash}" -t "${DOCKER_USER}/devstats-rust-bins" . || exit 56
  mkdir rust-bins || exit 57
  cid=$(docker create "${DOCKER_USER}/devstats-rust-bins" /none) || exit 56
  docker cp "${cid}:/rust-bins/." rust-bins || exit 56
  docker rm "${cid}" >/dev/null
  cd rust-bins || exit 57
  for b in structure gha2db calc_metric gha2db_sync import_affs annotations tags webhook devstats get_repos merge_dbs replacer vars ghapi2db columns hide_data website_data sync_issues runq api sqlitedb tsplit splitcrons
  do
    [ -x "$b" ] || { echo "$0: Rust binary $b was not built"; exit 58; }
  done
  tar cf ../grafana-bins.tar replacer sqlitedb runq || exit 6
  tar cf ../api-bins.tar api calc_metric || exit 44
  tar cf ../devstats-bins.tar * || exit 59
  cd ../../devstatscode || exit 3
fi

cd ../devstats-reports || exit 40
rm -f ../devstats-docker-images/devstats-reports.tar 2>/dev/null
cp ../velocity/forks.json ../velocity/lf_forks.json ../velocity/all_forks.json velocity/ || exit 46
tar cf ../devstats-docker-images/devstats-reports.tar sh sql affs rep contributors velocity find.sh || exit 41

cd ../devstats || exit 7
rm -f ../devstats-docker-images/index_*.html ../devstats-docker-images/devstats.tar ../devstats-docker-images/devstats-grafana.tar ../devstats-docker-images/*.svg ../devstats-docker-images/api-files.tar 2>/dev/null
tar cf ../devstats-docker-images/devstats.tar hide git metrics cdf devel util_sql envoy all lfn shared iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord scripts partials docs cron zephyr linux sam azf riff fn openwhisk openfaas cii prestodb godotengine kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni jaeger notary tuf rook vitess nats opa spiffe spire cloudevents telepresence helm openmetrics harbor etcd tikv cortex buildpacks falco dragonfly virtualkubelet kubeedge brigade crio networkservicemesh openebs opentelemetry thanos flux intoto strimzi kubevirt longhorn chubaofs keda smi argo volcano cnigenie keptn kudo cloudcustodian dex litmuschaos artifacthub kuma parsec bfe crossplane contour operatorframework chaosmesh serverlessworkflow k3s backstage tremor metal3 porter openyurt openservicemesh keylime schemahero cdk8s certmanager openkruise tinkerbell pravega kyverno gitopswg piraeus k8dash athenz kubeovn curiefense distribution ingraind kuberhealthy k8gb trickster emissaryingress wasmedge chaosblade vineyard antrea fluid submariner pixie meshery servicemeshperformance kubevela kubevip kubedl krustlet krator oras wasmcloud akri metallb karmada inclavarecontainers superedge cilium dapr openelb openclustermanagement vscodek8stools nocalhost kubearmor k8up kubers devfile knative fabedge confidentialcontainers openfunction teller sealer clusterpedia opencost aerakimesh curve openfeature kubewarden devstream hexapolicyorchestrator konveyor armada externalsecretsoperator serverlessdevs containerssh openfga kured carvel lima istio merbridge devspace capsule zot paralus carina ko opcr werf kubescape inspektorgadget clusternet keycloak sops headlamp slimtoolkit kepler pipecd eraser xline hwameistor kpt microcks kubeclipper kubeflow copacetic loggingoperator kanister kcp kcl kubeburner kuasar krknchaos kubestellar easegress spiderpool k8sgpt kubeslice connect kairos kubean koordinator radius bankvaults atlantis stacker trestlegrc kuadrant opengemini score bpfman loxilb cartography perses ratify hami shipwrightcncf flatcar kusionstack youki kaito sermant kmesh ovnkubernetes tratteria spin spinkube slimfaas container2wasm k0s runmenotebooks cloudnativepg kubefleet podmandesktop podmancontainertools bootc composefs drasi interlink cozystack kgateway kitops hyperlight opentofu cadence kagent urunc xregistry modelpack kserve oauth2proxy oxia holmesgpt cedarpolicy dalec openchoreo cohdi kubeelasti kaischeduler agones velero openeverest nmstate higress llmd apicurioregistry kbind curvine sdc cncf opencontainers spinnaker tekton jenkins jenkinsx cdevents ortelius pyrsia screwdrivercd shipwright allcdf graphql graphqljs graphiql expressgraphql graphqlspec hyperledger jsons/.keep util_sh projects.yaml companies.yaml skip_dates.yaml github_users.json || exit 8
tar cf ../devstats-docker-images/devstats-grafana.tar grafana/shared grafana/img/*.svg grafana/img/*.png grafana/*/change_title_and_icons.sh grafana/*/custom_sqlite.sql grafana/dashboards/*/*.json || exit 9
tar cf ../devstats-docker-images/api-files.tar metrics util_sql || exit 50
cp apache/www/index_*.html ../devstats-docker-images/ || exit 22
cp grafana/img/*.svg ../devstats-docker-images/ || exit 32
cp grafana/img/cncf-devstats.png ../devstats-docker-images/ || exit 51

cd "$cwd" || exit 10
rm -f devstats-docker-images.tar api-config.tar 2>/dev/null
tar cf devstats-docker-images.tar k8s example gql devstats-helm patches images/Makefile.* || exit 11
tar cf api-config.tar devstats-helm/projects.yaml || exit 45

if [ -z "$SKIP_FULL" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker build -f "./images/Dockerfile.full.test${SUFFIX:+.rust}" -t "${DOCKER_USER}/devstats-test${SUFFIX}${TAG}" . || exit 12
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker build -f "./images/Dockerfile.full.prod${SUFFIX:+.rust}" -t "${DOCKER_USER}/devstats-prod${SUFFIX}${TAG}" . || exit 33
  fi
fi

if [ -z "$SKIP_MIN" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker build -f "./images/Dockerfile.minimal.test${SUFFIX:+.rust}" -t "${DOCKER_USER}/devstats-minimal-test${SUFFIX}${TAG}" . || exit 13
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker build -f "./images/Dockerfile.minimal.prod${SUFFIX:+.rust}" -t "${DOCKER_USER}/devstats-minimal-prod${SUFFIX}${TAG}" . || exit 35
  fi
fi

if [ -z "$SKIP_GRAFANA" ]
then
  docker build -f ./images/Dockerfile.grafana -t "${DOCKER_USER}/devstats-grafana${TAG}" . || exit 14
fi

if [ -z "$SKIP_TESTS" ]
then
  docker build -f "./images/Dockerfile.tests${SUFFIX:+.rust}" -t "${DOCKER_USER}/devstats-tests${SUFFIX}${TAG}" . || exit 15
fi

if [ -z "$SKIP_PATRONI" ]
then
  # docker build -f ./images/Dockerfile.patroni -t "${DOCKER_USER}/devstats-patroni${TAG}" . || exit 16
  # docker build -f ./images/Dockerfile.patroni -t "${DOCKER_USER}/devstats-patroni-new${TAG}" . || exit 16
  # docker build -f ./images/Dockerfile.patroni.13 -t "${DOCKER_USER}/devstats-patroni-13${TAG}" . || exit 16
  # docker build -f ./images/Dockerfile.patroni.hll.13 -t "${DOCKER_USER}/devstats-patroni-hll-13${TAG}" . || exit 16
  docker build -f ./images/Dockerfile.patroni.18 -t "${DOCKER_USER}/devstats-patroni-18-hll${TAG}" . || exit 52
fi

if [ -z "$SKIP_STATIC" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker build -f ./images/Dockerfile.static.test -t "${DOCKER_USER}/devstats-static-test${SUFFIX}${TAG}" . || exit 24
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker build -f ./images/Dockerfile.static.prod -t "${DOCKER_USER}/devstats-static-prod${SUFFIX}${TAG}" . || exit 23
  fi
  if [ -z "$SKIP_STATIC_NOBINS" ]
  then
    docker build -f ./images/Dockerfile.static.cdf -t "${DOCKER_USER}/devstats-static-cdf${TAG}" . || exit 25
    docker build -f ./images/Dockerfile.static.graphql -t "${DOCKER_USER}/devstats-static-graphql${TAG}" . || exit 26
    docker build -f ./images/Dockerfile.static.default -t "${DOCKER_USER}/devstats-static-default${TAG}" . || exit 27
    docker build -f ./images/Dockerfile.static.backups -t "${DOCKER_USER}/backups-page${TAG}" . || exit 42
  fi
fi

if [ -z "$SKIP_REPORTS" ]
then
  docker build -f ./images/Dockerfile.reports -t "${DOCKER_USER}/devstats-reports${SUFFIX}${TAG}" . || exit 37
fi

if [ -z "$SKIP_API" ]
then
  if [ -z "$SKIP_PROD" ]
  then
    docker build -f ./images/Dockerfile.api -t "${DOCKER_USER}/devstats-api-prod${SUFFIX}${TAG}" . || exit 46
  fi
  if [ -z "$SKIP_TEST" ]
  then
    docker build -f ./images/Dockerfile.api -t "${DOCKER_USER}/devstats-api-test${SUFFIX}${TAG}" . || exit 48
  fi
fi

rm -f devstats.tar devstatscode.tar devstatscode-rust.tar devstats-bins.tar devstats-grafana.tar devstats-docker-images.tar grafana-bins.tar api-bins.tar api-config.tar api-files.tar devstats-reports.tar index_*.html *.svg
rm -rf rust-bins

if [ ! -z "$SKIP_PUSH" ]
then
  exit 0
fi

if [ -z "$SKIP_FULL" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker push "${DOCKER_USER}/devstats-test${SUFFIX}${TAG}" || exit 17
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker push "${DOCKER_USER}/devstats-prod${SUFFIX}${TAG}" || exit 34
  fi
fi

if [ -z "$SKIP_MIN" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker push "${DOCKER_USER}/devstats-minimal-test${SUFFIX}${TAG}" || exit 18
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker push "${DOCKER_USER}/devstats-minimal-prod${SUFFIX}${TAG}" || exit 36
  fi
fi

if [ -z "$SKIP_GRAFANA" ]
then
  docker push "${DOCKER_USER}/devstats-grafana${TAG}" || exit 19
fi

if [ -z "$SKIP_TESTS" ]
then
  docker push "${DOCKER_USER}/devstats-tests${SUFFIX}${TAG}" || exit 20
fi

if [ -z "$SKIP_PATRONI" ]
then
  # docker push "${DOCKER_USER}/devstats-patroni${TAG}" || exit 21
  # docker push "${DOCKER_USER}/devstats-patroni-new${TAG}" || exit 21
  # docker push "${DOCKER_USER}/devstats-patroni-13${TAG}" || exit 21
  # docker push "${DOCKER_USER}/devstats-patroni-hll-13${TAG}" || exit 21
  docker push "${DOCKER_USER}/devstats-patroni-18-hll${TAG}" || exit 53
fi

if [ -z "$SKIP_STATIC" ]
then
  if [ -z "$SKIP_TEST" ]
  then
    docker push "${DOCKER_USER}/devstats-static-test${SUFFIX}${TAG}" || exit 28
  fi
  if [ -z "$SKIP_PROD" ]
  then
    docker push "${DOCKER_USER}/devstats-static-prod${SUFFIX}${TAG}" || exit 24
  fi
  if [ -z "$SKIP_STATIC_NOBINS" ]
  then
    docker push "${DOCKER_USER}/devstats-static-cdf${TAG}" || exit 29
    docker push "${DOCKER_USER}/devstats-static-graphql${TAG}" || exit 30
    docker push "${DOCKER_USER}/devstats-static-default${TAG}" || exit 31
    docker push "${DOCKER_USER}/backups-page${TAG}" || exit 43
  fi
fi

if [ -z "$SKIP_REPORTS" ]
then
  docker push "${DOCKER_USER}/devstats-reports${SUFFIX}${TAG}" || exit 38
fi

if [ -z "$SKIP_API" ]
then
  if [ -z "$SKIP_PROD" ]
  then
    docker push "${DOCKER_USER}/devstats-api-prod${SUFFIX}${TAG}" || exit 47
  fi
  if [ -z "$SKIP_TEST" ]
  then
    docker push "${DOCKER_USER}/devstats-api-test${SUFFIX}${TAG}" || exit 49
  fi
fi

echo 'OK'
