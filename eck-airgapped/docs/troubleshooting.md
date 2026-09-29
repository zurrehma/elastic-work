# Troubleshooting Fleet in an air-gapped ECK cluster

## Agents show "Degraded" with `Elasticsearch request failed: 404 Not Found`

The agent reached Elasticsearch, but the index template / data stream it writes to does not exist.
In an air-gapped cluster this almost always means the integration package was never installed.

1. Check the registry is up and Kibana is using it:
   ```sh
   kubectl -n elastic get packageregistry package-registry
   kubectl -n elastic logs deploy/kibana-kb | grep -i registry
   ```
2. Check the package is installed (Kibana → Fleet → Integrations → Installed), or via API:
   ```sh
   curl -sk -u "elastic:$PW" https://localhost:5601/api/fleet/epm/packages/system \
     -H 'kbn-xsrf: true' | jq '.item.status'
   ```
   Anything other than `installed` → reinstall it; with `xpack.fleet.packages` in `30-kibana.yaml` this happens at Kibana start-up.
3. Check the templates exist:
   ```sh
   GET _index_template/logs-system.*
   GET _index_template/logs-windows.*
   ```
4. Version skew: agent, Fleet Server, Kibana, Elasticsearch and the package registry image should all be on the same version (`versions.env`).

## Output URL mismatch

If a custom Fleet output points at an Ingress or load balancer, a path rewrite on the proxy can turn every bulk request into a 404.
Test from inside an agent pod:
```sh
kubectl -n elastic exec -it ds/elastic-agent-agent -- \
  curl -sk -o /dev/null -w '%{http_code}\n' https://elasticsearch-es-http.elastic.svc:9200/
```
`401` means routing works (no credentials sent); `404` means the URL or path is wrong.

## Images fail to pull

`ErrImagePull` for `docker.elastic.co/...` means the operator is not using the internal registry.
Check `config.containerRegistry` in the operator values, and that the image path in the internal registry matches the upstream path
(`elasticsearch/elasticsearch:<ver>`, `elastic-agent/elastic-agent:<ver>`, ...).

## TLS between Fleet Server and agents

ECK issues certificates for `fleet-server-agent-http.elastic.svc`. If agents enrol through any other hostname,
add it to the Fleet Server `http.tls.selfSignedCertificate.subjectAltNames` or supply your own certificate.
