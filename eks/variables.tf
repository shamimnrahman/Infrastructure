variable "env" {
  description = "Environment name (used to find dependee tfstates)"
}

variable "aws_region" {
  description = "AWS Region to use"
}

variable "aws_profile" {
  description = "AWS Profile to load from local AWS configs"
}

variable "worker_type" {
  description = "EC2 instance type to use for EKS workers"
  default     = "m5.large"
}

variable "tfstate_region" {
  description = "AWS region to read remote state from"
}

variable "tfstate_bucket" {
  description = "S3 bucket to read remote state from"
}

variable "tfstate_lock_table" {
  description = "DynamoDB table used to lock remote state"
}
