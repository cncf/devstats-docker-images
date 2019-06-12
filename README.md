# devstats-docker-images

DevStats docker images: minimal (hourly cron job sync), full (provisioning/bootstraping), Grafana (UI endpoint), Patroni (database), tests.


# Create and test images

Create and remove docker images:

- To create DevStats docker container images and publish them, use: `DOCKER_USER=... ./images/build_images.sh`.
- To drop local DevStats docker container images use: `DOCKER_USER=... ./images/remove_images.sh`.
- You can add various flags to skip specific images like `SKIP_FULL=1` or `SKIP_MIN=1` see `images/build_images.sh`.
- You can skip publishing to docker hub via `SKIP_PUSH=1`.


# Testing images

Using kubernetes:

- To test sync DevStats image (`devstats-minimal` container): `DOCKER_USER=... ./images/test_image_kubernetes.sh devstats-minimal`.
- To test provisioning DevStats image (`devstats` container): `DOCKER_USER=... ./images/test_image_kubernetes.sh devstats`.
- To test Grafana DevStats image (`devstats-grafana` container): `DOCKER_USER=... ./images/test_image_kubernetes.sh devstats-grafana`.
- To execute test coverage: `./tests/test_from_docker.sh`.
- Making pushes to GitHb triggers automatic Travis CI builds.

Using docker:

- Replace `./images/test_image_kubernetes.sh` with `./images/test_image_docker.sh`.
- To execute test coverage: `./tests/test_from_k8s.sh`.


# Adding new projects

See `cncf/devstats-helm`:`ADDING_NEW_PROJECTS.md` or `NEW_PROJECT.md` (this is only for updating docker images and adding to bare kubernetes deployment).
