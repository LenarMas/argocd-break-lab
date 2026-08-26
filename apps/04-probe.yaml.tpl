apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: s04
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${REV}
    path: manifests/s04-web
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-04
  syncPolicy:
    automated:
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
