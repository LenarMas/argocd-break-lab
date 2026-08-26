apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: s05
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${REV}
    path: charts/s05-web
    helm:
      valueFiles:
        - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-05
  syncPolicy:
    automated:
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
