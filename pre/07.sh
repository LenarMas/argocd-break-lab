#!/usr/bin/env bash
# Simulates "someone deployed this by hand before ArgoCD owned it"
set -euo pipefail
kubectl create namespace demo-07 --dry-run=client -o yaml | kubectl apply -f -
kubectl -n demo-07 apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: s07-web
  labels:
    app: s07-web-old
spec:
  replicas: 1
  selector:
    matchLabels:
      app: s07-web-old
  template:
    metadata:
      labels:
        app: s07-web-old
    spec:
      containers:
        - name: web
          image: nginx:1.27-alpine
YAML
