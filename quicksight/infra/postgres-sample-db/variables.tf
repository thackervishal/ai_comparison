variable "aws_region" {
  description = "AWS region to deploy into. Also selects which QuickSight IP range gets allow-listed -- see quicksight_ip_ranges.tf."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name/tag all resources."
  type        = string
  default     = "qs-mb-sample-db"
}

variable "instance_type" {
  description = "EC2 instance type. t3.micro is free-tier eligible and plenty for a single small Postgres container."
  type        = string
  default     = "t3.micro"
}

variable "docker_image" {
  description = "The exact Docker image to run -- same one already used for the local Metabase QA stack, so both sides of the comparison hit identical data."
  type        = string
  default     = "metabase/qa-databases:postgres-sample-15"
}

variable "my_ip_cidr" {
  description = <<-EOT
    Your own IP as a /32, e.g. "203.0.113.4/32" (find it with `curl -s ifconfig.me`).
    Required for psql/Metabase access to the box and (if enabled) SSH troubleshooting.
    No default on purpose -- an empty value would leave the box unreachable except
    from QuickSight, which is safer than guessing a CIDR for you.
  EOT
  type        = string
  default     = ""
}

variable "allow_ssh" {
  description = "Whether to open port 22 to my_ip_cidr, for debugging the Docker container via SSH."
  type        = bool
  default     = true
}

variable "extra_allowed_cidr_blocks" {
  description = "Any additional CIDRs (beyond my_ip_cidr and the QuickSight range) allowed to reach Postgres on 5432."
  type        = list(string)
  default     = []
}

variable "quicksight_ip_override" {
  description = "Override the QuickSight data-source IP range looked up from var.aws_region in quicksight_ip_ranges.tf (e.g. if AWS has updated it since this was written, or your region isn't in the map)."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
