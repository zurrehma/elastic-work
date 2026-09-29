#!/usr/bin/env bash
# Installs the ECK operator from the local chart and applies the stack, waiting for each tier to be healthy.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HERE/versions.env"
BUNDLE_DIR="${BUNDLE_DIR:-$HERE/bundle}"
NS=elastic

helm upgrade --install elastic-operator "${BUNDLE_DIR}/eck-operator-${ECK_VERSION}.tgz" \
  --namespace elastic-system --create-namespace \
  -f "$HERE/helm/eck-operator-values.yaml" \
  --set image.repository="${INTERNAL_REGISTRY}/eck/eck-operator" \
  --set config.containerRegistry="${INTERNAL_REGISTRY}" \
  --wait

kubectl apply -f "$HERE/manifests/00-namespace.yaml"
kubectl apply -f "$HERE/manifests/10-package-registry.yaml"
kubectl apply -f "$HERE/manifests/20-elasticsearch.yaml"

wait_for() {
  local kind=$1 name=$2 jsonpath=$3 want=$4
  echo ">> waiting for ${kind}/${name} (${want})"
  for _ in $(seq 1 90); do
    got=$(kubectl -n "$NS" get "$kind" "$name" -o jsonpath="$jsonpath" 2>/dev/null || true)
    [[ "$got" == "$want" ]] && return 0
    sleep 10
  done
  echo "timed out waiting for ${kind}/${name}" >&2
  kubectl -n "$NS" describe "$kind" "$name" >&2
  exit 1
}

wait_for elasticsearch elasticsearch '{.status.health}' green
kubectl apply -f "$HERE/manifests/30-kibana.yaml"
wait_for kibana kibana '{.status.health}' green

kubectl apply -f "$HERE/manifests/40-fleet-rbac.yaml"
kubectl apply -f "$HERE/manifests/50-fleet-server.yaml"
wait_for agent fleet-server '{.status.health}' green
kubectl apply -f "$HERE/manifests/60-elastic-agent.yaml"

echo ">> done. elastic user password:"
kubectl -n "$NS" get secret elasticsearch-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d; echo
