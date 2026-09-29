# Elastic platform samples

Reference implementations for running the Elastic Stack in production-style environments.
Each folder is self-contained and has its own README.

| Project | What it shows |
|---|---|
| [`eck-airgapped/`](eck-airgapped/) | ECK 3.5 + Elastic Stack 9.5 in a Kubernetes cluster with no internet access: image mirroring, in-cluster Elastic Package Registry, Fleet Server and Fleet-managed Elastic Agents, troubleshooting for integration 404s. |
| [`terraform-multicloud-eck/`](terraform-multicloud-eck/) | One Terraform module that deploys ECK + Elasticsearch + Kibana on EKS, GKE or AKS, with a small root per cloud (network, cluster, storage class, provider auth). |
| [`logstash-cisco-asa-ecs/`](logstash-cisco-asa-ecs/) | Logstash pipeline that parses Cisco ASA firewall syslog into ECS, with GeoIP, data stream output, ILM and a Docker-based test. |

## Validation

- ECK manifests checked against the ECK 3.5.0 CRD schemas; operator values rendered with `helm template`.
- All three Terraform roots pass `terraform validate`.
- Logstash filter tested in Docker (Logstash 9.5.0) against the sample logs; full pipeline passes `logstash -t`.

These are sample configurations: review sizing, security settings and secrets handling before using them in production.
