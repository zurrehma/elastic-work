#!/usr/bin/env bash
# Runs the filter against sample-logs/asa.log in a throwaway Logstash container
# and checks the parsed ECS fields. No Elasticsearch needed.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
LS_VERSION="${LS_VERSION:-9.5.0}"
OUT="$(mktemp -d)"
chmod 777 "$OUT"

docker run --rm -i \
  -v "$HERE/test/00-stdin.conf:/cfg/00-stdin.conf:ro" \
  -v "$HERE/pipeline/20-filter.conf:/cfg/20-filter.conf:ro" \
  -v "$HERE/test/99-file.conf:/cfg/99-file.conf:ro" \
  -v "$OUT:/out" \
  -e XPACK_MONITORING_ENABLED=false \
  "docker.elastic.co/logstash/logstash:${LS_VERSION}" \
  logstash -f /cfg/ --log.level=error --pipeline.workers 1 < "$HERE/sample-logs/asa.log"

python3 "$HERE/test/check.py" "$OUT/parsed.ndjson"
