# ECK in an air-gapped Kubernetes cluster

Elasticsearch, Kibana, Fleet Server and Elastic Agent on Elastic Cloud on Kubernetes (ECK),
for a cluster with **no outbound internet access**.

| Component | Version |
|---|---|
| ECK operator | 3.5.0 |
| Elastic Stack | 9.5.0 |
| Elastic Package Registry | 9.5.0 (self-hosted) |

## What makes air-gapped different

| Problem when offline | How this setup handles it |
|---|---|
| Images come from `docker.elastic.co` | `scripts/mirror-images.sh` bundles them on a connected host and pushes them to an internal registry; the operator's `containerRegistry` rewrites every image it creates. |
| Fleet downloads integrations from `epr.elastic.co` | A `PackageRegistry` resource runs the registry in-cluster and Kibana points at it with `packageRegistryRef`. |
| Integrations installed lazily → agents hit `404` on missing data streams | `xpack.fleet.packages` installs System, Windows, Kubernetes, Fleet Server and Elastic Agent packages when Kibana starts. |
| Kibana keeps trying to reach public endpoints | `xpack.fleet.isAirGapped: true` and operator telemetry disabled. |

## Layout

```
versions.env                  single place to bump versions / registry
helm/eck-operator-values.yaml operator image + containerRegistry
manifests/
  00-namespace.yaml
  10-package-registry.yaml    in-cluster Elastic Package Registry
  20-elasticsearch.yaml       3 dedicated masters + 3 hot data/ingest nodes
  30-kibana.yaml              Fleet config, preinstalled packages, agent policies
  40-fleet-rbac.yaml          service accounts and cluster roles
  50-fleet-server.yaml        Fleet Server (2 replicas)
  60-elastic-agent.yaml       Fleet-managed agent DaemonSet
scripts/
  mirror-images.sh            bundle (online) / push (offline)
  install.sh                  ordered install with health checks
docs/troubleshooting.md       404s from integrations, output URLs, image pulls, TLS
```

## Usage

```sh
# 1. On a machine with internet access
./scripts/mirror-images.sh bundle        # creates ./bundle with images + chart + checksums

# 2. Copy ./bundle into the air-gapped network, then
./scripts/mirror-images.sh push          # load and push to INTERNAL_REGISTRY
./scripts/install.sh                     # operator, then ES → Kibana → Fleet Server → agents
```

Set `INTERNAL_REGISTRY` in `versions.env` (and the matching values in `helm/eck-operator-values.yaml`) before running.

## Sizing notes

- `node.store.allow_mmap: false` avoids changing `vm.max_map_count` on nodes; for heavy search workloads, set the sysctl on the nodes and remove it.
- Hot nodes spread across zones with a topology spread constraint; masters rely on ECK's default pod anti-affinity.
- Storage uses the cluster's default StorageClass; set `storageClassName` in the volume claim templates if you need a specific class.

See [docs/troubleshooting.md](docs/troubleshooting.md) for the common failure modes.
