variable "project" {
  type    = string
  default = "notes-api"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Set by CI/CD to the git commit SHA on each deploy"
}

variable "desired_count" {
  type    = number
  default = 2
}
