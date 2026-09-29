#!/usr/bin/env bash
# Moves everything ECK needs across the air gap.
#
#   On a connected host:   ./mirror-images.sh bundle   -> writes ./bundle/ (images tarball + Helm chart)
#   Inside the air gap:    ./mirror-images.sh push     -> loads the tarball and pushes to $INTERNAL_REGISTRY
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../versions.env
source "$HERE/versions.env"
BUNDLE_DIR="${BUNDLE_DIR:-$HERE/bundle}"

IMAGES=(
  "eck/eck-operator:${ECK_VERSION}"
  "elasticsearch/elasticsearch:${STACK_VERSION}"
  "kibana/kibana:${STACK_VERSION}"
  "elastic-agent/elastic-agent:${STACK_VERSION}"
  "package-registry/distribution:${EPR_VERSION}"
)

bundle() {
  mkdir -p "$BUNDLE_DIR"
  local refs=()
  for img in "${IMAGES[@]}"; do
    echo ">> pulling docker.elastic.co/${img}"
    docker pull "docker.elastic.co/${img}"
    refs+=("docker.elastic.co/${img}")
  done
  echo ">> saving images to ${BUNDLE_DIR}/elastic-images.tar"
  docker save -o "${BUNDLE_DIR}/elastic-images.tar" "${refs[@]}"

  echo ">> downloading eck-operator chart ${ECK_VERSION}"
  helm repo add elastic https://helm.elastic.co >/dev/null
  helm repo update elastic >/dev/null
  helm pull elastic/eck-operator --version "${ECK_VERSION}" -d "$BUNDLE_DIR"

  (cd "$BUNDLE_DIR" && sha256sum ./* > SHA256SUMS)
  echo ">> bundle ready: copy ${BUNDLE_DIR} into the air-gapped network"
}

push() {
  (cd "$BUNDLE_DIR" && sha256sum -c SHA256SUMS)
  docker load -i "${BUNDLE_DIR}/elastic-images.tar"
  for img in "${IMAGES[@]}"; do
    # Same path, new registry: this is the layout ECK's containerRegistry setting expects.
    docker tag "docker.elastic.co/${img}" "${INTERNAL_REGISTRY}/${img}"
    docker push "${INTERNAL_REGISTRY}/${img}"
  done
  echo ">> all images pushed to ${INTERNAL_REGISTRY}"
}

case "${1:-}" in
  bundle) bundle ;;
  push) push ;;
  *) echo "usage: $0 bundle|push" >&2; exit 1 ;;
esac
