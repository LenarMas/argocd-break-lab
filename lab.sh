#!/usr/bin/env bash
# ./lab.sh deploy 03    -> apply a broken scenario
# ./lab.sh status 03    -> quick triage dump
# ./lab.sh reset 03     -> tear it down
# ./lab.sh reset all
set -euo pipefail

REPO_URL="${REPO_URL:-$(git remote get-url origin 2>/dev/null || true)}"
REV="${REV:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)}"

if [[ -z "$REPO_URL" ]]; then
  echo "Set REPO_URL to the https URL of your pushed repo, e.g."
  echo "  export REPO_URL=https://github.com/LenarMas/argocd-break-lab.git"
  exit 1
fi
export REPO_URL REV

tpl_for() { ls apps/"$1"-*.yaml.tpl 2>/dev/null | head -n1; }

cmd="${1:-}"; n="${2:-}"

case "$cmd" in
  deploy)
    f=$(tpl_for "$n"); [[ -n "$f" ]] || { echo "no scenario $n"; exit 1; }
    [[ -x "pre/$n.sh" ]] && ./pre/"$n".sh
    envsubst < "$f" | kubectl apply -f -
    echo ">> applied $f. Give it 30s, then: ./lab.sh status $n"
    ;;
  status)
    app="s$n"
    echo "=== argocd app get ==="; argocd app get "$app" 2>/dev/null || kubectl -n argocd get application "$app" -o yaml | sed -n '/status:/,$p' | head -60
    echo; echo "=== conditions ==="
    kubectl -n argocd get application "$app" -o jsonpath='{.status.conditions}' ; echo
    echo; echo "=== operationState ==="
    kubectl -n argocd get application "$app" -o jsonpath='{.status.operationState.message}' ; echo
    echo; echo "=== workloads in demo-$n ==="
    kubectl -n "demo-$n" get all,endpoints 2>/dev/null || true
    ;;
  reset)
    if [[ "$n" == "all" ]]; then
      kubectl -n argocd delete application --all --ignore-not-found
      kubectl delete ns -l '!kubernetes.io/metadata.name' --ignore-not-found >/dev/null 2>&1 || true
      for i in 01 02 03 04 05 06 07 08 09; do kubectl delete ns "demo-$i" --ignore-not-found; done
      kubectl -n argocd delete appproject restricted --ignore-not-found
    else
      kubectl -n argocd delete application "s$n" --ignore-not-found
      kubectl delete ns "demo-$n" --ignore-not-found
    fi
    ;;
  *) echo "usage: ./lab.sh {deploy|status|reset} <NN|all>"; exit 1;;
esac
