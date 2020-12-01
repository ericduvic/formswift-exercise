output "region" {
  value = var.region
}

output "cluster_arn" {
  value = module.fargate.cluster_arn
}

output "service_arn" {
  value = module.fargate.service_arn
}

output "lb_address" {
  value = module.fargate.lb_address
}

output "ecr_address" {
  value = module.fargate.ecr_address
}