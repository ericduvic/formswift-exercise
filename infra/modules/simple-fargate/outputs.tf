output "cluster_arn" {
  value = aws_ecs_cluster.cluster.arn
}

output "service_arn" {
  value = module.fargate.service_arn
}

output "lb_address" {
  value = module.alb.dns_name
}

output "ecr_address" {
  value = aws_ecr_repository.ecr.repository_url
}