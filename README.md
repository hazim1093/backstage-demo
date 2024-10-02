# backstage-demo

This repo consists of an automated procedure for deploying and updating backstage.

## Solution

This repo consists of an automated procedure for deploying and updating backstage using the following technologies:

- **Kubernetes**: As the container orchestrator, to manage the lifecycle of the containers and handling failures gracefully
- **ArgoCD**: To automate deployment of backstage via GitOps
- **Renovate**: To automate updates whenever a new version of backstage is published to the registry

This setup will make sure that Backstage is updated automatically via pull requests (or automatically merging PRs), and that the installation stays in a working state even if something wrong happens during an update.

## Steps to run

### Prerequisites

The following tools need to be installed and configured:

- [Docker](https://docs.docker.com/engine/install/) or [Podman](https://podman.io/docs/installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [helm](https://helm.sh/docs/intro/install/)

### Bootstrapping Environment

In order to setup the kubernetes cluster (kind) and required tools use the [bootstrap script](./bootstrap.sh).

1. Run script
   ```sh
   ./bootstrap.sh
   ```

2. Get ArgoCD admin password:
    ```sh
    kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    ```

3. Open ArgoCD: [https://argocd.127.0.0.1.nip.io](https://argocd.127.0.0.1.nip.io) and wait for everything to sync.

4. Access backstage: [https://backstage.127.0.0.1.nip.io](https://backstage.127.0.0.1.nip.io)

#### Explanation

The bootstrap script will:
- Install kind cluster called `bs-cluster-01`
- Deploy nginx ingress controller in the cluster for accessing apps
- Deploy ArgoCD in order to enable GitOps

Once the script has finished successfully, ArgoCD will manage all components and apps via GitOps.

To delete or start over again, delete the kind cluster:
```sh
kind delete cluster -n bs-cluster-01
```

### Updating

An example PR for automated update of backstage has been created in this repo: [Pull#4](https://github.com/hazim1093/backstage-demo/pull/4)

In order to test update you can fork the repo and use the fork instead, before bootstrapping the environment:

1. Fork the repository
2. Replace references to the repository:
   ```sh
   find . -name "*.yaml" -type f -exec sed -i '' 's|https://github.com/hazim1093/backstage-demo|<your-fork-url>|g' {} +;

   find . -name "*.yaml" -type f -exec sed -i '' 's|hazim1093/backstage-demo|<fork-user/backstage-demo>|g' {} +;
   ```
3. Update `backstage.backstage.image.tag` in [apps/backstage/values.yaml](./apps/backstage/values.yaml) and commit, to update the version number
4. To configure renovate, create a secret with your Github Token:
   ```sh
    kubectl create secret generic renovate-secrets -n renovate \
        --from-literal=RENOVATE_TOKEN="<Github Access Token>" \
        --from-literal=RENOVATE_GIT_AUTHOR="renovate@example.com"
   ```
5. In order to test a "faulty" update, use the docker image: `hazim/backstage-demo:faulty`. This release should fail to start, but the previous one should still be available.

## Assumptions / Future Considerations

The following assumptions have been made in this setup:

- The Backstage docker images used is built from an existing community docker image by [The Platformers](https://www.platformers.community), instead of building backstage from scratch for this demo. The Appconfig for backstage has some dummy catalog resources.
- The docker images can be found in [images/backstage](./images/backstage/)
- SSL Certificates are not configured
- All components are not deployed in HA fashion
- Backstage is configured without persistent storage and uses in-memory database for simplicity.
