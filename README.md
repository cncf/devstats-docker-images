# devstats-docker-images

DevStats docker images: minimal (hourly cron job sync), full (provisioning/bootstraping), Grafana (UI endpoint)


# Create and test images

Create and remove docker images:

- To create DevStats docker container images and publish them, use: `DOCKER_USER=... ./images/build_images.sh`.
- To drop local DevStats docker container images use: `DOCKER_USER=... ./images/remove_images.sh`.


# Testing images

Using kubernetes:

- To test sync DevStats image (`devstats-minimal` container): `DOCKER_USER=... ./images/test_image_kubernetes.sh devstats-minimal`.
- To test provisioning DevStats image (`devstats` container): `DOCKER_USER=... ./images/test_image_kubernetes.sh devstats`.
- To test Grafana DevStats image (`devstats-grafana` container): `DOCKER_USER=... ./images/test_image_kubernetes.sh devstats-grafana`.

Using docker:

- Replace `./images/test_image_kubernetes.sh` with `./images/test_image_docker.sh`.


# Adding new projects

See `NEW_PROJECT.md`.
