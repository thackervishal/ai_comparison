# Uses the account's default VPC to keep this cheap and simple -- this is a
# throwaway comparison box, not production infra. Default VPC subnets are
# public (route to an Internet Gateway) by default, which is what we need
# for QuickSight (a SaaS product with no "localhost"/VPC-peered connector on
# Standard edition) to reach it.

data "aws_vpc" "default" {
  default = true
}

# Not every AZ in a region supports every instance type (e.g. t3.micro is
# missing from us-east-1e as of 2026-07-22), so restrict subnet selection to
# AZs that actually offer var.instance_type rather than picking blind.
data "aws_ec2_instance_type_offerings" "available" {
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
  location_type = "availability-zone"
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availability-zone"
    values = data.aws_ec2_instance_type_offerings.available.locations
  }
}

# Just need one subnet for a single instance.
locals {
  subnet_id = data.aws_subnets.default.ids[0]
}
