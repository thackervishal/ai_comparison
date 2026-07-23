# Uses the account's default VPC to keep this cheap and simple -- this is a
# throwaway comparison box, not production infra. Default VPC subnets are
# public (route to an Internet Gateway) by default, which is what we need
# for QuickSight (a SaaS product with no "localhost"/VPC-peered connector on
# Standard edition) to reach it.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Just need one subnet for a single instance.
locals {
  subnet_id = data.aws_subnets.default.ids[0]
}
