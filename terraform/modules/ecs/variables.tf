variable "project" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "environment" {
  type    = string
  default = "production"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Overridden by CI/CD on each deploy with the git SHA"
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 4
}

variable "secrets_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
