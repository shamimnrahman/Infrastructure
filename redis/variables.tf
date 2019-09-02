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

variable "name" {
  description = "Name to use for the Redis cluster (used as part of a name prefix so multiple different Redis clusters can be made)"
}

variable "node_type" {
  description = "Elasticache instance type to use for Redis nodes"
}

variable "num_node_groups" {
  description = "Number of Redis shards to create"
}

variable "replicas_per_node_group" {
  description = "Number of failover replicas to create per Redis shard"
}

variable "port" {
  description = "Port to use for Redis"
  default     = 6379
}

variable "automatic_failover_enabled" {
  default = true
}
