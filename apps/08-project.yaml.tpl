apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: restricted
  namespace: argocd
spec:
  description: Locked down project
  sourceRepos:
    - https://github.com/LenarMas/argocd-break-lab
  destinations:
    - server: https://kubernetes.default.svc
      namespace: default
  clusterResourceWhitelist: []
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: s08
  namespace: argocd
spec:
  project: restricted
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${REV}
    path: manifests/s01-whoami
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-08
  syncPolicy:
    automated:
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
