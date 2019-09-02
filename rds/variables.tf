variable "env" {
  description = "Environment name"
}

variable "name" {
  description = "Name for this DB instance (used as part of resource names and descriptions)"
}

variable "force_ssl" {
  description = "Force incoming connections to use SSL"
  default     = false
}

variable "db_name" {
  description = "Name of the database to create"
}

variable "port" {
  description = "Port for the DB to listen on (e.g. 5432 for psql)"
}

variable "allocated_storage" {
  description = "Number GB of storage to allocate for the DB"
}

variable "storage_type" {
  description = "RDS storage type to use"
  default     = "gp2"
}

variable "iops" {
  description = "IOPS to provision (only for storage_type of 'io1')"
  default     = ""
}

variable "engine" {
  description = "RDS Engine to use (e.g. 'postgres')"
}

variable "engine_version" {
  description = "RDS engine version to use (e.g. '10.4')"
}

variable "parameter_group_family" {
  description = "RDS Parameter Group family (e.g. postgres10)"
}

variable "instance_class" {
  description = "DB instance class to use (e.g. db.t2.micro)"
}

variable "username" {
  description = "DB master username"
}

variable "backup_retention_period" {
  description = "How many days to retain backups for"
}

variable "multi_az" {
  description = "Whether or not this should be multi-az"
  default     = true
}

variable "replicate_source_db" {
  description = "If this DB should be a read-replica, the identifier of the master DB (should be in form ENV-NAME-postgresql)"
  default     = ""
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
