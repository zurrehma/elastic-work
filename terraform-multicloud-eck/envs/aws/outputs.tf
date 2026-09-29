output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "elastic_password_command" {
  value = module.eck.elastic_password_command
}
