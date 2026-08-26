apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: s06
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${REV}
    path: manifests/s06-web
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-06
  syncPolicy:
    automated:
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
