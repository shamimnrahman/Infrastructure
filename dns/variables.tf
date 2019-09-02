variable "env" {
  description = "Environment name"
}

variable "aws_region" {
  description = "AWS Region to use"
}

variable "aws_profile" {
  description = "AWS Profile to load from local AWS configs"
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

variable "root_domain" {
  description = "Root DNS name from which to base the k8s automatic DNS"
}
