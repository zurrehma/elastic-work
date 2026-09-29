# ECK on AWS, GCP and Azure with Terraform

One Terraform module deploys the ECK operator and an Elasticsearch + Kibana stack;
three small environment roots create a managed Kubernetes cluster on each cloud and call it.

```
modules/eck/     cloud-agnostic: eck-operator + eck-stack Helm releases
envs/aws/        VPC + EKS (managed node group, EBS CSI via Pod Identity, gp3 StorageClass)
envs/gcp/        VPC-native regional GKE cluster + node pool
envs/azure/      AKS across 3 availability zones
```

| | AWS | GCP | Azure |
|---|---|---|---|
| Cluster | EKS (`terraform-aws-modules/eks` v21) | GKE regional | AKS |
| Nodes | 3 × m6i.xlarge | 3 × e2-standard-4 (one per zone) | 3 × Standard_D4s_v5 (zones 1-3) |
| Storage | `gp3` (EBS CSI, encrypted) | `standard-rwo` (PD CSI) | `managed-csi` (Azure Disk CSI) |
| Auth for Helm | `aws eks get-token` | Google access token | AKS client certificate |

Versions: ECK 3.5.0, Elastic Stack 9.5.0, Terraform ≥ 1.6. All three roots pass `terraform validate`.

## Why Helm releases instead of `kubernetes_manifest`

`kubernetes_manifest` needs the ECK CRDs to exist at **plan** time, which breaks a single `apply` on a new cluster.
Both the operator and the stack are Helm releases (`eck-operator`, `eck-stack`), so one `terraform apply` builds the cluster and the stack.

## Usage

```sh
cd envs/aws        # or envs/gcp, envs/azure
terraform init
terraform apply    # gcp: -var project_id=...   azure: -var subscription_id=...
$(terraform output -raw kubeconfig_command)
kubectl -n elastic get elasticsearch,kibana
eval "$(terraform output -raw elastic_password_command)"
kubectl -n elastic port-forward svc/kibana-kb-http 5601
```

## Module inputs (`modules/eck`)

| Variable | Default | Notes |
|---|---|---|
| `storage_class_name` | — | required; each env passes its cloud's class |
| `stack_version` | `9.5.0` | Elasticsearch and Kibana |
| `eck_version` | `3.5.0` | operator chart |
| `es_node_count` | `3` | |
| `es_memory` | `4Gi` | request = limit |
| `es_storage_size` | `50Gi` | per node |
| `kibana_service_type` | `ClusterIP` | `LoadBalancer` to expose publicly |

## Production notes

- Use a remote backend (S3 + DynamoDB lock, GCS, or Azure Storage) instead of local state.
- The example uses one node pool for everything; for larger clusters, split masters and data tiers into separate node sets and node pools.
- Restrict the API server endpoints (EKS public access CIDRs, GKE master authorized networks, AKS authorized IP ranges).
