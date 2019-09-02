variable "env" {
  description = "Environment name"
}

variable "namespace_prefix" {
  description = "Namespace to create (will have -ENV appended to it)"
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
