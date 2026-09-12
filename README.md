# devstats-docker-images

DevStats docker images: minimal (hourly cron job sync), full (provisioning/bootstraping), Grafana (UI endpoint), Patroni (database), tests.


# Create and test images

Create and remove docker images:

- To create DevStats docker container images and publish them, use: `DOCKER_USER=... ./images/build_images.sh`.
- To drop local DevStats docker container images use: `DOCKER_USER=... ./images/remove_images.sh`.
- You can add various flags to skip specific images like `SKIP_FULL=1`, `SKIP_MIN=1`, `SKIP_TEST=1`, `SKIP_PROD=1` see `images/build_images.sh`.
- You can skip publishing to docker hub via `SKIP_PUSH=1`.
- `IMAGE_TAG=xyz` builds and pushes every image as `name:xyz` instead of the default tag (`latest`) - e.g. `IMAGE_TAG=try SKIP_PROD=1 SKIP_GRAFANA=1 SKIP_PATRONI=1 SKIP_STATIC_NOBINS=1 SKIP_TESTS=1 DOCKER_USER=... ./images/build_images.sh` to try new images in the test namespace (`kubectl -n devstats-test set image cronjob/devstats-riff devstats-riff=DOCKER_USER/devstats-minimal-test:go127`) without touching the tags the production CronJobs pull.

Image contents (Go images, `images/Dockerfile.*`):

- Binaries are built with `golang:1.27` (statically linked, stripped) and installed under `/usr/bin`; the full images also have `/etc/gha2db` (metrics, SQLs, data files) and `/go/src/devstats` (the `devstats` data repository + `devstats-docker-images` scripts, `patch.sh`-ed for the test/prod hostname, with symlinks to the binaries).
- No source code is shipped: after the build the full images remove everything that came with the `devstatscode` clone (Go/Rust sources, `.git`, `go.mod`/`go.sum`, developer scripts) unless the `devstats`/`devstats-docker-images` tarballs provide a file at the same path (`cron/`, `devel/`, `git/` scripts, `projects.yaml`, ...), so `/go/src/devstats` is exactly the same file set in the Go and `-rust` images.
- The full images use the official `postgres:18-alpine` image (psql/pg_dump/pg_restore matching the server version, `docker-entrypoint.sh`) minus server-only leftovers nothing in DevStats uses (no PostgreSQL server ever runs from these images): the LLVM JIT (`libLLVM` ~170 MB, `llvmjit.so`, bitcode), C headers and static libraries. Because layers are additive the trimmed root filesystem is flattened into a fresh image (`FROM scratch` + `COPY --from=pgbase / /`) and the base image's runtime configuration (`ENV`, `VOLUME`, `ENTRYPOINT`, `STOPSIGNAL`, `EXPOSE`, `CMD`) is re-declared in the Dockerfile - keep it in sync with `docker image inspect postgres:18-alpine` when bumping the base image. Result: `devstats-test`/`devstats-prod` ~600 MB instead of ~900 MB with identical behaviour.

Shortcuts:

- Build only API images: `./example/build_api.sh`.

Rust images (DevStats binaries from the Rust port in `devstatscode/rust` instead of the Go ones):

- `RUST=1 DOCKER_USER=... SKIP_PATRONI=1 ./images/build_images.sh` builds every image that contains at least one DevStats binary under an alternate name with the `-rust` suffix: `devstats-test-rust`, `devstats-prod-rust`, `devstats-minimal-test-rust`, `devstats-minimal-prod-rust`, `devstats-tests-rust`, `devstats-static-test-rust`, `devstats-static-prod-rust`, `devstats-reports-rust`, `devstats-api-prod-rust`, `devstats-api-test-rust`. The regular (Go) images are not touched and images without DevStats binaries (grafana, patroni, static-cdf/graphql/default, backups-page) are skipped in this mode. All `SKIP_*` flags work as usual.
- The binaries are compiled inside Docker (`images/Dockerfile.rust-bins`, `rust:alpine` builder, static Linux musl executables with the same names/CLI/env as the Go ones) (a local intermediate image `DOCKER_USER/devstats-rust-bins`, never pushed, exported to `./rust-bins/`) and shipped via `grafana-bins.tar`/`api-bins.tar` (same Dockerfiles as the Go images) and `devstats-bins.tar` (`images/Dockerfile.{full,minimal}.{prod,test}.rust`, generated from the Go Dockerfiles by `images/rust_dockerfile.sh` so project lists stay single-sourced; `images/Makefile.{full,minimal}.rust` lay them out). The `-rust` images have the same runtime content as the Go ones (same base images and packages, `/etc/gha2db`, identical `/go/src/devstats` file set, binaries under the same names, no source code in either) but are smaller: static Rust binaries are less than half the size of the Go ones. Docker with BuildKit (Docker 23+) is required; the cargo registry and build directory are BuildKit cache mounts, so rebuilds are incremental.
- `devstats-tests-rust` runs `rust/test.sh` (rustfmt, clippy, unit tests and the Go⇄Rust compatibility tests against a local PostgreSQL 18): `docker run -ti DOCKER_USER/devstats-tests-rust`.
- `RUST=1 DOCKER_USER=... ./images/remove_images.sh` removes the `-rust` images.
- `DOCKER_USER=... ./images/build_rust_bins.sh [dir]` only builds the static Rust binaries (into `./rust-bins/` by default) - `build_images.sh` uses it in `RUST=1` mode and `devstats/devel/create_grafana_shared_data.sh` takes the `replacer`, `sqlitedb` and `runq` shipped in the shared Grafana data from it, so grafana pods run the same binaries as the images.
- Since 2026-09-12 the `-rust` images are the ones deployed (all CronJobs and the API in `devstats-test` and `devstats-prod`, `devstats-helm` defaults); the Go images are still built and pushed under their original names as the rollback path.


# Testing images

Using kubernetes:

- To test sync DevStats image (`devstats-minimal-test`, `devstats-minimal-prod` containers): `DOCKER_USER=... ./images/test_image_kubernetes.sh devstats-minimal-test`.
- To test provisioning DevStats image (`devstats-test`, `devstats-prod` containers): `DOCKER_USER=... ./images/test_image_kubernetes.sh devstats-prod`.
- To test Grafana DevStats image (`devstats-grafana` container): `DOCKER_USER=... ./images/test_image_kubernetes.sh devstats-grafana`.
- To execute test coverage: `./tests/test_from_docker.sh`.
- Making pushes to GitHb triggers automatic Travis CI builds.

Using docker:

- Replace `./images/test_image_kubernetes.sh` with `./images/test_image_docker.sh`.
- To execute test coverage: `./tests/test_from_k8s.sh`.


# Reports

- To run `devstats-reports` image using docker: `DOCKER_USER=... ./images/devstats_reports_docker.sh`.


# Adding new projects

See `cncf/devstats-helm`:`ADDING_NEW_PROJECTS.md` or `NEW_PROJECT.md` (this is only for updating docker images and adding to bare kubernetes deployment).
