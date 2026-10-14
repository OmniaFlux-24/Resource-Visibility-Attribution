output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "postgres_endpoint" {
  description = "The connection endpoint for PostgreSQL 17"
  value       = module.postgres17.db_instance_endpoint
  sensitive   = true
}

output "postgres_database_name" {
  description = "The name of the database"
  value       = module.postgres17.db_instance_name
}