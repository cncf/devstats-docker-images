#!/bin/bash
# Builds the Rust port of the DevStats binaries (../devstatscode/rust) as static Linux musl executables inside
# Docker (images/Dockerfile.rust-bins, rust:alpine; BuildKit cache mounts make rebuilds incremental) and copies
# them into a directory: ./rust-bins/ in devstats-docker-images by default, or the first argument.
# The same binaries end up in the "-rust" images (images/build_images.sh with RUST=1) and in the shared Grafana
# data (devstats/devel/create_grafana_shared_data.sh ships replacer, sqlitedb and runq for the grafana pods),
# so everything runs bit-identical executables.
#   DOCKER_USER=lukaszgryglicki ./images/build_rust_bins.sh [output-dir]
# DEVSTATSCODE=/path overrides the location of the devstatscode checkout (default: ../devstatscode).
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi
images="$(cd "$(dirname "$0")/.." && pwd)" || exit 50
code="${DEVSTATSCODE:-${images}/../devstatscode}"
out="${1:-${images}/rust-bins}"
case "${out}" in
  /*) ;;
  *) out="$(pwd)/${out}" ;;
esac

cd "${code}" || exit 3
if [ ! -f rust/compile.sh ]
then
  echo "$0: ${code}/rust does not look like the Rust port of devstatscode"
  exit 51
fi
rm -f "${images}/devstatscode-rust.tar" 2>/dev/null
# Rust sources (without build directories) -> compiled inside Docker to static Linux binaries.
tar --exclude='target' --exclude='rust/.cargo' -cf "${images}/devstatscode-rust.tar" rust || exit 5
rust_hash=$(git rev-parse HEAD 2>/dev/null || echo None)
cd "${images}" || exit 55
docker build -f ./images/Dockerfile.rust-bins --build-arg "DEVSTATS_GIT_HASH=${rust_hash}" -t "${DOCKER_USER}/devstats-rust-bins" . || exit 56
rm -f devstatscode-rust.tar
rm -rf "${out}"
mkdir -p "${out}" || exit 57
cid=$(docker create "${DOCKER_USER}/devstats-rust-bins" /none) || exit 56
docker cp "${cid}:/rust-bins/." "${out}" || exit 56
docker rm "${cid}" >/dev/null
cd "${out}" || exit 57
for b in structure gha2db calc_metric gha2db_sync import_affs annotations tags webhook devstats get_repos merge_dbs replacer vars ghapi2db columns hide_data website_data sync_issues runq api sqlitedb tsplit splitcrons
do
  [ -x "$b" ] || { echo "$0: Rust binary $b was not built"; exit 58; }
done
echo "$0: Rust binaries (commit ${rust_hash}) are in ${out}"
