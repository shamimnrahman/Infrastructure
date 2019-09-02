variable "aws_region" {
  description = "AWS Region to use"
}

variable "aws_profile" {
  description = "AWS Profile to load from local AWS configs"
}

variable "env" {
  description = "Environment to tag resources with"
}

variable "vpc_cidr_block" {
  description = "CIDR block to use as the base for the VPC's subnets"
  default     = "10.0.0.0/16"
}
