# argocd-break-lab

Nine deliberately broken Argo CD Applications for interview practice. Each one fails in a
different layer: repo-server, controller, Kubernetes API, or the workload itself.

## Setup (about 10 minutes)

1. Push this folder to a **public** GitHub repo (Argo CD needs to reach it without credentials):

```bash
cd argocd-break-lab
git init && git add -A && git commit -m "lab"
gh repo create argocd-break-lab --public --source=. --push
```

2. Open it in a Codespace (the devcontainer enables docker-in-docker so kind works), or stay local.

3. Build the cluster and install Argo CD:

```bash
./setup.sh
export REPO_URL=$(git remote get-url origin)
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
argocd login localhost:8080 --username admin --insecure
```

## Running a drill

```bash
./lab.sh deploy 03      # break it
./lab.sh status 03      # triage dump
./lab.sh reset 03       # clean up
```

Fix each one by editing the file in the repo and pushing, then `argocd app sync s03`.
That push-then-sync loop is the whole point. Do not fix things with `kubectl edit`,
because self-heal will revert you and the interviewer will notice.

## Triage loop (say this out loud while you work)

Work outside in. Four questions, in order:

1. **Can Argo CD read the source?**
   `argocd app get sNN` -> ComparisonError, `app path does not exist`, helm/kustomize render errors.
   Logs: `kubectl -n argocd logs deploy/argocd-repo-server --tail=50`

2. **Can it apply what it rendered?**
   Sync result / `operationState.message` -> namespace not found, RBAC denied, immutable field,
   admission webhook rejection. Logs: `kubectl -n argocd logs deploy/argocd-application-controller --tail=50`

3. **Did Kubernetes accept it but the workload is unhealthy?**
   `kubectl -n demo-NN get pods`, `describe pod`, `get events --sort-by=.lastTimestamp`
   -> ImagePullBackOff, CrashLoopBackOff, probe failures, pending on resources.

4. **Is it green but still not working?**
   `kubectl -n demo-NN get endpoints` and `kubectl run tmp --rm -it --image=curlimages/curl -- curl svc:port`
   -> selector mismatch, wrong targetPort, wrong service port.

Useful throughout: `argocd app diff sNN`, `argocd app history sNN`, `argocd app sync sNN --dry-run`,
`kubectl -n argocd get application sNN -o yaml | yq '.status'`.

## The drills

| # | Command | What you should see | Layer |
|---|---------|--------------------|-------|
| 01 | `./lab.sh deploy 01` | App will not even compare | repo-server |
| 02 | `./lab.sh deploy 02` | Renders fine, apply is rejected | API server |
| 03 | `./lab.sh deploy 03` | Synced, not Healthy | workload |
| 04 | `./lab.sh deploy 04` | Pods running, never Ready, stuck Progressing | workload |
| 05 | `./lab.sh deploy 05` | Helm render failure, then a second failure after you fix the first | repo-server |
| 06 | `./lab.sh deploy 06` | Synced and Healthy, but nothing answers | service wiring |
| 07 | `./lab.sh deploy 07` | Sync fails on an existing resource | API server |
| 08 | `./lab.sh deploy 08` | App refuses to run at all | Argo CD RBAC / AppProject |
| 09 | `./lab.sh deploy 09` | Scale it by hand, watch it stay drifted | sync policy |

For 09, after deploying: `kubectl -n demo-09 scale deploy s09-web --replicas=5`, then explain
why Argo CD reports OutOfSync and does nothing about it, and what you would change.

Answers in HINTS.md. Try to hit each one in under five minutes before you look.
