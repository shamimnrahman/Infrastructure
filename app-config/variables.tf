variable "env" {
  description = "Environment name"
}

variable "configmap_name" {
  description = "Name of the configmap to create"
}

variable "configmap_namespace_prefix" {
  description = "Namespace to put the configmap in (will have -ENV appended to it)"
}

variable "db_state_name" {
  description = "Name of the db instance to read remote state from (the name of the directory in the aws-infrastructure repo, like 'sp6-db')"
}

variable "redis_state_name" {
  description = "Name of the redis instance to read remote state from"
}

// Variables needed to read remote state
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
