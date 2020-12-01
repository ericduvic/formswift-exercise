variable "app" {
  type        = string
  description = "The name of the app"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID in which to deploy"
}

variable "app_subnets" {
  description = "Subnets in which to deploy fargate"
}

variable "lb_subnets" {
  description = "Subnets in which to deploy the load balancer"
}

variable "cpu" {
  description = "(optional) The CPU count for each task instance"
  default     = 256
}

variable "memory" {
  description = "(optional) The amount of RAM to dedicate to each task instance"
  default     = 512
}

variable "task_container_port" {
  description = "(optional) The port to expose for the container"
  default     = 80
}

variable "task_container_tag" {
  type        = string
  description = "(optional) The tag of the image to deploy"
  default     = "latest"
}

variable "desired_count" {
  type        = number
  description = "(optional) The desired number of instances"
  default     = 2
}