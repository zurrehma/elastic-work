# Cloud-agnostic part: the same operator and stack on EKS, GKE or AKS.
# Both are Helm releases, so no CRD has to exist at plan time.

resource "helm_release" "eck_operator" {
  name             = "elastic-operator"
  repository       = "https://helm.elastic.co"
  chart            = "eck-operator"
  version          = var.eck_version
  namespace        = "elastic-system"
  create_namespace = true
  wait             = true
}

resource "helm_release" "eck_stack" {
  name             = "elastic-stack"
  repository       = "https://helm.elastic.co"
  chart            = "eck-stack"
  version          = var.eck_stack_chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [yamlencode({
    "eck-elasticsearch" = {
      enabled          = true
      fullnameOverride = "elasticsearch"
      version          = var.stack_version
      nodeSets = [{
        name  = "default"
        count = var.es_node_count
        config = {
          "node.store.allow_mmap" = false
        }
        podTemplate = {
          spec = {
            containers = [{
              name = "elasticsearch"
              resources = {
                requests = { memory = var.es_memory, cpu = "1" }
                limits   = { memory = var.es_memory }
              }
            }]
          }
        }
        volumeClaimTemplates = [{
          metadata = { name = "elasticsearch-data" }
          spec = {
            accessModes      = ["ReadWriteOnce"]
            storageClassName = var.storage_class_name
            resources        = { requests = { storage = var.es_storage_size } }
          }
        }]
      }]
    }
    "eck-kibana" = {
      enabled          = true
      fullnameOverride = "kibana"
      version          = var.stack_version
      count            = 1
      elasticsearchRef = { name = "elasticsearch" }
      http = {
        service = { spec = { type = var.kibana_service_type } }
      }
    }
  })]

  depends_on = [helm_release.eck_operator]
}
