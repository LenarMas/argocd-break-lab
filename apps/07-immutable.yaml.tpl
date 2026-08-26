apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: s07
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${REV}
    path: manifests/s07-web
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-07
  syncPolicy:
    automated:
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
