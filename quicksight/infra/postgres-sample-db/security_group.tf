resource "aws_security_group" "postgres" {
  name        = "${var.project_name}-sg"
  description = "Allow Postgres (and optionally SSH) access to the QuickSight/Metabase sample DB box"
  vpc_id      = data.aws_vpc.default.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-sg"
  })
}

# QuickSight's published outbound range for this region -- see quicksight_ip_ranges.tf.
resource "aws_vpc_security_group_ingress_rule" "postgres_from_quicksight" {
  security_group_id = aws_security_group.postgres.id
  description       = "Postgres from QuickSight (${var.aws_region})"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = local.quicksight_cidr
}

# Your own IP -- for psql / local Metabase testing against this box.
resource "aws_vpc_security_group_ingress_rule" "postgres_from_me" {
  count = var.my_ip_cidr != "" ? 1 : 0

  security_group_id = aws_security_group.postgres.id
  description       = "Postgres from my IP"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip_cidr
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_extra" {
  for_each = toset(var.extra_allowed_cidr_blocks)

  security_group_id = aws_security_group.postgres.id
  description       = "Postgres from ${each.value}"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_me" {
  count = var.allow_ssh && var.my_ip_cidr != "" ? 1 : 0

  security_group_id = aws_security_group.postgres.id
  description       = "SSH from my IP"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.my_ip_cidr
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.postgres.id
  description       = "Allow all outbound (needed to pull the Docker image)"
  ip_protocol        = "-1"
  cidr_ipv4          = "0.0.0.0/0"
}
