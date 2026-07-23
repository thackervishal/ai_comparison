output "public_ip" {
  description = "Paste this into QuickSight's 'New dataset -> PostgreSQL' Server field."
  value       = aws_instance.sample_db.public_ip
}

output "instance_id" {
  value = aws_instance.sample_db.id
}

output "quicksight_cidr_used" {
  description = "The QuickSight IP range that was allow-listed for var.aws_region."
  value       = local.quicksight_cidr
}

output "connection_string" {
  description = "psql-style connection string (password omitted -- it's 'metasample123', baked into the image)."
  value       = "postgresql://metabase@${aws_instance.sample_db.public_ip}:5432/sample"
}

output "ssh_command" {
  description = "Only useful if var.allow_ssh = true and my_ip_cidr is set."
  value       = "ssh ec2-user@${aws_instance.sample_db.public_ip}"
}
