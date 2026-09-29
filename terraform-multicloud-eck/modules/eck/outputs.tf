output "namespace" {
  value = var.namespace
}

output "elasticsearch_url" {
  description = "In-cluster Elasticsearch endpoint."
  value       = "https://elasticsearch-es-http.${var.namespace}.svc:9200"
}

output "kibana_service" {
  value = "kibana-kb-http.${var.namespace}.svc"
}

output "elastic_password_command" {
  description = "Command to read the elastic superuser password."
  value       = "kubectl -n ${var.namespace} get secret elasticsearch-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d"
}
