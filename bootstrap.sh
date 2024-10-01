#!/usr/bin/env bash
set -e

wait_for_ready () {
    LABEL=$1
    NAMESPACE=$2

    while true; do
    STATUS=$(kubectl get pods -l $LABEL -n $NAMESPACE -o jsonpath='{.items[].status.conditions[?(@.type=="Ready")].status}')
    if [[ "$STATUS" == "True" ]]; then
        echo "Pod(s) with label '$LABEL' are available."
        break
    fi
    echo "Waiting for pod(s) with label '$LABEL' to become available..."
    sleep 3
    done
}

# Required Binaries
commands=("kind" "helm" "kubectl")

echo """
===========================================
Checking required binaries ...
===========================================
"""
# Check if required binaries are installed
for cmd in "${commands[@]}"; do
  if command -v $cmd &> /dev/null; then
    echo "$cmd version: $($cmd version --short 2>/dev/null || $cmd version)"
  else
    echo "$cmd is not installed"
    exit 1
  fi
done


echo """
===========================================
Starting bootstrap ...
===========================================
"""
# Create cluster
kind create cluster --config cluster/kind.yaml

# Install ingress-nginx
kubectl apply -k components/ingress-nginx
wait_for_ready "app.kubernetes.io/component=controller" "ingress-nginx"

# Install Argocd
helm dependency build components/argo-cd
helm upgrade --install argo-cd components/argo-cd -n argo-cd --create-namespace
wait_for_ready "app.kubernetes.io/instance=argo-cd" "argo-cd"

# Enable gitops: Install app of apps
kubectl apply -f 0-argocd-apps/0-app-of-apps.yaml

echo """
===========================================
Bootstrap complete
===========================================

Access ArgoCD: http://argocd.127.0.0.1.nip.io

Fetch admin password:
kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
"""
