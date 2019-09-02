output "name" {
  description = "Database name"
  value       = "${var.db_name}"
}

output "username" {
  description = "Database master username"
  value       = "${var.username}"
}

output "password" {
  description = "Database master password"
  value       = "${random_string.password.result}"
  sensitive   = true
}

output "host" {
  description = "Database host"
  value       = "${aws_db_instance.this.address}"
}

output "port" {
  description = "Database port"
  value       = "${aws_db_instance.this.port}"
}
