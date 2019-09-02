output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "public_subnet_ids" {
  value = "${module.vpc.public_subnets}"
}

output "private_subnet_ids" {
  value = "${module.vpc.private_subnets}"
}

output "elasticache_subnet_group_name" {
  value = "${module.vpc.elasticache_subnet_group_name}"
}

output "db_subnet_group_name" {
  value = "${module.vpc.database_subnet_group}"
}
