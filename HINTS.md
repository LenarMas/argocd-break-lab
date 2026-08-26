# Answers

Read only after you have tried.

**01 bad path.** `spec.source.path` is `manifests/s01-whoami-app`, the directory is
`manifests/s01-whoami`. Symptom is a ComparisonError condition, no resource tree at all.
Same class of failure as a wrong `targetRevision` or a private repo with no credentials.

**02 missing namespace.** Destination namespace `demo-02` does not exist and the Application
has no `CreateNamespace=true` in `syncPolicy.syncOptions`. Sync fails with `namespaces "demo-02"
not found`. Either add the sync option or manage the Namespace object in git with a sync wave.

**03 bad image tag.** `nginx:1.29-alpin`. App is Synced because the Deployment applied cleanly,
but Health is Degraded / Progressing and pods sit in ImagePullBackOff. This is the one that
proves Synced and Healthy are two independent things.

**04 probe mismatch.** Readiness and liveness probe `/healthz` on port 8080, nginx serves `/` on 80.
Pods restart or never become Ready, so the app never reaches Healthy and a sync with
`--timeout` would hang. Fix the path and port, or point the probe at `/` on 80.

**05 helm, two bugs.** First: `helm.valueFiles` lists `values-prod.yaml`, which does not exist,
so repo-server fails to render. Point it at `values.yaml`. Then the render succeeds but produces
`replicas:` empty, because the template uses `.Values.replicas` while values.yaml defines
`replicaCount`. Fix one side or the other. Reproduce locally with
`helm template charts/s05-web` before blaming Argo CD.

**06 selector mismatch.** Deployment pods are labelled `app: s06-web`, the Service selector is
`app: s06web`. Argo CD is green because both objects applied. `kubectl -n demo-06 get endpoints
s06-web` shows `<none>`. Fix the selector. Also note the Service listens on 8080 and targets 80,
which is fine but worth saying out loud so nobody thinks you missed it.

**07 immutable field.** A Deployment already exists in the cluster with
`spec.selector.matchLabels.app: s07-web-old`. Git says `s07-web`. Selectors are immutable, so
sync fails with `field is immutable`. Options, in the order you should present them: delete the
existing Deployment and let Argo CD recreate it, or add `Replace=true` to sync options, or as a
last resort `argocd app sync s07 --replace`. Say why the blunt option is risky in production.

**08 AppProject restriction.** The `restricted` project only allows `sourceRepos:
https://github.com/argoproj/*` and only the `default` namespace. The Application errors with
`application repo ... is not permitted in project` and `destination ... is not permitted`.
Fix the project spec, or move the app to a project that allows it. This is the one candidates
usually miss because they keep debugging the manifests.

**09 drift.** `syncPolicy.automated` has `selfHeal: false` and `prune: false`. A manual scale
shows OutOfSync and Argo CD leaves it. Turn on selfHeal to snap it back, and explain the
tradeoff: selfHeal plus prune means git is truly the source of truth, but it also means an
emergency manual scale during an incident gets reverted under you, so teams often gate it.
