# devstats-docker-images

DevStats docker images: minimal (hourly cron job sync), full (provisioning/bootstraping), Grafana (UI endpoint), Patroni (database), tests.


# Create and test images

Create and remove docker images:

- To create DevStats docker container images and publish them, use: `DOCKER_USER=... ./images/build_images.sh`.
- To drop local DevStats docker container images use: `DOCKER_USER=... ./images/remove_images.sh`.
- You can add various flags to skip specific images like `SKIP_FULL=1`, `SKIP_MIN=1`, `SKIP_TEST=1`, `SKIP_PROD=1` see `images/build_images.sh`.
- You can skip publishing to docker hub via `SKIP_PUSH=1`.

Shortcuts:

- Build only API images: `./example/build_api.sh`.


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
