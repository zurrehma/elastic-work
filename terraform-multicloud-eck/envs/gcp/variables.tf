variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west3"
}

variable "name" {
  type    = string
  default = "eck-demo"
}

variable "node_machine_type" {
  type    = string
  default = "e2-standard-4"
}
