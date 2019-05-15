# Adding new project

- Update `./images/build_images.sh` (add project's directory).
- Update `./k8s/projects.yaml` `./example/projects.yaml`, `./gql/projects.yaml` (add project where needed).
- Update `./k8s/all_*.txt`, `./example/all_*.txt`, `./gql/all_*.txt` (lists of projects to process).
- Run `DOCKER_USER=... ./images/build_images.sh` to build a new image.
- Eventually run `DOCKER_USER=... ./images/remove_images.sh` to remove image locally (new image is pushed to the Docker hub).


# If using Helm

- Update `github.com/cncf/devstats-helm-lf/devstats-helm/values.yaml` (add project).
- Now: N - index of the new project added to `github.com/cncf/devstats-helm-lf/devstats-helm/values.yaml`. M=N+1. Inside `github.com/cncf/devstats-lf-helm`:
- Run `helm install ./devstats-helm --set skipSecrets=1,skipBootstrap=1,skipCrons=1,skipGrafanas=1,skipServices=1,skipPostgres=1,skipIngress=1,indexProvisionsFrom=N,indexProvisionsTo=M,indexPVsFrom=N,indexPVsTo=M` to create provisioning pods.
- Run `helm install ./devstats-helm --set skipSecrets=1,skipPVs=1,skipBootstrap=1,skipProvisions=1,skipGrafanas=1,skipServices=1,skipPostgres=1,skipIngress=1,indexCronsFrom=N,indexCronsTo=M` to create cronjobs (they will wait for provisioning to finish).
- Run `helm install ./devstats-helm --set skipSecrets=1,skipPVs=1,skipBootstrap=1,skipProvisions=1,skipCrons=1,skipPostgres=1,skipIngress=1,indexGrafanasFrom=N,indexGrafanasTo=M,indexServicesFrom=N,indexServicesTo=M` to create grafana deployments and services. Grafanas will be usable when full provisioning is completed.
- You can do 3 last steps in one step instead: `helm install ./devstats-helm --set skipSecrets=1,skipBootstrap=1,skipPostgres=1,skipIngress=1,indexProvisionsFrom=N,indexProvisionsTo=M,indexCronsFrom=N,indexCronsTo=M,indexGrafanasFrom=N,indexGrafanasTo=M,indexServicesFrom=N,indexServicesTo=M,indexPVsFrom=N,indexPVsTo=M`.
- Eventually do something very similar for `cncf/devstats-helm-graphql`.


# If using manual Kubernetes deployment

- Update `github.com/cncf/devstats-k8s-lf/kubernetes/cron_them_all.sh` (optional if using helm chart, but needed for manual K8s deployment).
- Update `github.com/cncf/devstats-k8s-lf/kubernetes/provision_them_all.sh` (optional if using helm chart, but needed for manual K8s deployment).
- Update `github.com/cncf/devstats-k8s-lf/kubernetes/grafanas_for_all.sh` (optional if using helm chart, but needed for manual K8s deployment).
- Update `github.com/cncf/devstats-k8s-lf/kubernetes/services_for_all.sh` (optional if using helm chart, but needed for manual K8s deployment).
- Use `github.com/cncf/devstats-k8s-lf` repo to delete and redeploy objects as needed (manually).
