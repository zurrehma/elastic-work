variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "name" {
  description = "Cluster and VPC name."
  type        = string
  default     = "eck-demo"
}

variable "kubernetes_version" {
  type    = string
  default = "1.33"
}

variable "node_instance_type" {
  type    = string
  default = "m6i.xlarge"
}
