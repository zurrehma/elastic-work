variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "name" {
  type    = string
  default = "eck-demo"
}

variable "node_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}
