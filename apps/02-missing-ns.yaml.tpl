apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: s02
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${REV}
    path: manifests/s02-web
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-02
  syncPolicy:
    automated:
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
