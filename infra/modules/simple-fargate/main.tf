resource "aws_ecs_cluster" "cluster" {
  name               = var.app

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Terraform = "true"
  }
}

module "fargate" {
  source                 = "umotif-public/ecs-fargate/aws"
  version                = "~> 5.0.0"

  name_prefix            = var.app
  vpc_id                 = var.vpc_id
  private_subnet_ids     = var.app_subnets
  lb_arn                 = module.alb.arn

  cluster_id             = aws_ecs_cluster.cluster.id

  desired_count          = var.desired_count

  force_new_deployment   = true

  task_container_image   = "${aws_ecr_repository.ecr.repository_url}:${var.task_container_tag}"
  task_definition_cpu    = var.cpu
  task_definition_memory = var.memory

  task_container_port    = var.task_container_port

  health_check = {
    port = var.task_container_port
    path = "/"
  }

  tags = {
    Terraform = "true"
  }

  depends_on = [
    module.alb,
    aws_ecr_repository.ecr
  ]
}

module "alb" {
  source             = "umotif-public/alb/aws"
  version            = "~> 1.2.1"

  name_prefix        = var.app

  load_balancer_type = "application"

  internal           = false
  vpc_id             = var.vpc_id
  subnets            = var.lb_subnets

  tags = {
    Terraform = "true"
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = module.alb.arn
  port              = var.task_container_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.fargate.target_group_arn
  }
}

resource "aws_security_group_rule" "alb_ingress" {
  security_group_id = module.alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.task_container_port
  to_port           = var.task_container_port
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "task_ingress" {
  security_group_id        = module.fargate.service_sg_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.task_container_port
  to_port                  = var.task_container_port
  source_security_group_id = module.alb.security_group_id
}

resource "aws_ecr_repository" "ecr" {
  name                 = var.app
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}