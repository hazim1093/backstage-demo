#!/usr/bin/env bash
set -e

wait_for_ready () {
    DEPLOYMENT_NAME=$1
    NAMESPACE=$2

    while true; do
    STATUS=$(kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')
    if [[ "$STATUS" == "True" ]]; then
        echo "Deployment $DEPLOYMENT_NAME is available."
        break
    fi
    echo "Waiting for deployment $DEPLOYMENT_NAME to become available..."
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

# Install Argocd
helm dependency build components/argo-cd
helm upgrade --install argo-cd components/argo-cd -n argo-cd --create-namespace
wait_for_ready "argo-cd-argocd-server" "argo-cd"

# Install ingress-nginx
kubectl apply -k components/ingress-nginx
wait_for_ready "ingress-nginx-controller" "ingress-nginx"

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
