apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: s01
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${REV}
    path: manifests/s01-whoami
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-01
  syncPolicy:
    automated:
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
