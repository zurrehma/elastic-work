variable "eck_version" {
  description = "ECK operator Helm chart version (same as the ECK release)."
  type        = string
  default     = "3.5.0"
}

variable "eck_stack_chart_version" {
  description = "eck-stack Helm chart version."
  type        = string
  default     = "0.20.0"
}

variable "stack_version" {
  description = "Elasticsearch / Kibana version."
  type        = string
  default     = "9.5.0"
}

variable "namespace" {
  description = "Namespace for Elasticsearch and Kibana."
  type        = string
  default     = "elastic"
}

variable "es_node_count" {
  description = "Number of Elasticsearch nodes (all roles)."
  type        = number
  default     = 3
}

variable "es_memory" {
  description = "Memory request/limit per Elasticsearch pod."
  type        = string
  default     = "4Gi"
}

variable "es_storage_size" {
  description = "Persistent volume size per Elasticsearch node."
  type        = string
  default     = "50Gi"
}

variable "storage_class_name" {
  description = "StorageClass for Elasticsearch volumes. Each cloud passes its own (gp3, standard-rwo, managed-csi)."
  type        = string
}

variable "kibana_service_type" {
  description = "Service type for Kibana (ClusterIP or LoadBalancer)."
  type        = string
  default     = "ClusterIP"
}
