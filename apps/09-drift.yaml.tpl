apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: s09
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${REV}
    path: manifests/s09-web
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-09
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
      - CreateNamespace=true
