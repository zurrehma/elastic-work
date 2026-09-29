#!/usr/bin/env bash
# Creates the ILM policy and index template before Logstash starts writing.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
: "${ES_URL:?set ES_URL, e.g. https://localhost:9200}"
: "${ES_API_KEY:?set ES_API_KEY (base64 id:key)}"

es() { curl -sS --fail-with-body --cacert "${ES_CA_CERT:-ca.crt}" -H "Authorization: ApiKey ${ES_API_KEY}" -H 'Content-Type: application/json' "$@"; echo; }

es -X PUT "${ES_URL}/_ilm/policy/logs-cisco.asa" -d @"$HERE/elasticsearch/ilm-policy.json"
es -X PUT "${ES_URL}/_index_template/logs-cisco.asa" -d @"$HERE/elasticsearch/index-template.json"
