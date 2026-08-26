#!/usr/bin/env bash
# One-time setup: kind cluster + Argo CD.
# Works in a GitHub Codespace or locally with Docker Desktop.
set -euo pipefail

CLUSTER="${CLUSTER:-argolab}"

case "$(uname -s)" in Linux) OS=linux;; Darwin) OS=darwin;; *) echo "unsupported OS"; exit 1;; esac
case "$(uname -m)" in x86_64|amd64) ARCH=amd64;; arm64|aarch64) ARCH=arm64;; *) echo "unsupported arch"; exit 1;; esac

SUDO=""; [[ $EUID -ne 0 ]] && SUDO="sudo"
need() { command -v "$1" >/dev/null 2>&1; }
get()  { curl -sSLo /tmp/"$1" "$2"; chmod +x /tmp/"$1"; $SUDO mv /tmp/"$1" /usr/local/bin/"$1"; }

need docker || { echo "Docker is not available. In Codespaces make sure the devcontainer built."; exit 1; }
need kind    || { echo ">> installing kind";    get kind   "https://kind.sigs.k8s.io/dl/v0.23.0/kind-${OS}-${ARCH}"; }
need kubectl || { echo ">> installing kubectl"; get kubectl "https://dl.k8s.io/release/$(curl -sSL https://dl.k8s.io/release/stable.txt)/bin/${OS}/${ARCH}/kubectl"; }
need argocd  || { echo ">> installing argocd";  get argocd  "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-${OS}-${ARCH}"; }
need helm    || { echo ">> installing helm";    curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | $SUDO bash; }

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo ">> creating kind cluster (2-3 minutes)"
  kind create cluster --name "$CLUSTER"
fi
kubectl cluster-info --context "kind-$CLUSTER" >/dev/null

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
echo ">> installing Argo CD"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml >/dev/null

# serve the UI over plain HTTP so Codespaces port forwarding works without cert warnings
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'

echo ">> waiting for Argo CD (a few minutes on first run)"
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=600s
kubectl -n argocd rollout restart deploy/argocd-server
kubectl -n argocd rollout status deploy/argocd-server --timeout=600s

PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)

cat <<TXT

=====================================================================
Argo CD is up.

  username: admin
  password: $PW

Open the UI:
  kubectl -n argocd port-forward svc/argocd-server 8080:80 &
  then open http://localhost:8080
  (in Codespaces, use the PORTS tab and click the globe icon on 8080)

Log in with the CLI:
  argocd login localhost:8080 --plaintext --username admin --password '$PW'

Then point the lab at your repo:
  export REPO_URL=\$(git remote get-url origin)
  ./lab.sh deploy 01
=====================================================================
TXT
