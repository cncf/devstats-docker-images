# Adding new project

- Update `./images/build_images.sh` (add project's directory).
- Update `./k8s/projects.yaml` (add project).
- Update `github.com/cncf/devstats-helm-lf/devstats-helm/values.yaml` (add project).
- Update `./k8s/all_*.txt` (lists of projects to process).
- Update `github.com/cncf/devstats-k8s-lf/kubernetes/cron_then_all.sh` (optional if using helm chart, but needed for manual K8s deployment).
- Update `github.com/cncf/devstats-k8s-lf/kubernetes/provision_them_all.sh` (optional if using helm chart, but needed for manual K8s deployment).
- Run `DOCKER_USER=... ./images/build_images.sh` to build a new image.
- Now: N - index of the new project added to `github.com/cncf/devstats-helm-lf/devstats-helm/values.yaml`. M=N+1. Inside `github.com/cncf/devstats-lf-helm`:
- Run `helm install ./devstats-helm --set skipSecrets=1,skipPV=1,skipBootstrap=1,skipCrons=1,skipGrafanas=1,skipServices=1,indexProvisionsFrom=N,indexProvisionsTo=M` to create provisioning pods.
- Run `helm install ./devstats-helm --set skipSecrets=1,skipPV=1,skipBootstrap=1,skipProvisions=1,skipGrafanas=1,skipServices=1,indexCronsFrom=N,indexCronsTo=M` to create cronjobs (they will wait for provisioning to finish).
- Run `helm install ./devstats-helm --set skipSecrets=1,skipPV=1,skipBootstrap=1,skipProvisions=1,skipCrons=1,indexGrafanasFrom=N,indexGrafanasTo=M,indexServicesFrom=N,indexServicesTo=M` to create grafana deployments and services. Grafanas will be usable when full provisioning is completed.
- You can do 3 last steps in one step instead: `helm install ./devstats-helm --set skipSecrets=1,skipPV=1,skipBootstrap=1,indexProvisionsFrom=N,indexProvisionsTo=M,indexCronsFrom=N,indexCronsTo=M,indexGrafanasFrom=N,indexGrafanasTo=M,indexServicesFrom=N,indexServicesTo=M`.
