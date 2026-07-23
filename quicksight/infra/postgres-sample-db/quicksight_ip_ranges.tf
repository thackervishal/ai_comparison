# QuickSight's outbound IP range for data-source connectivity, per region.
#
# IMPORTANT: this is NOT available through the `aws_ip_ranges` Terraform data
# source (checked: ip-ranges.json has no "QUICKSIGHT" service value, only
# "AMAZON", "EC2", "S3", etc.). AWS instead publishes it as a plain table on
# this docs page, one /27 per region:
#   https://docs.aws.amazon.com/quicksight/latest/user/regions.html
# ("IP address range for data source connectivity" column)
#
# Captured 2026-07-22. These can change without notice -- if QuickSight
# can't reach the instance, re-check that page and either update the map
# below or pass var.quicksight_ip_override.

locals {
  quicksight_ip_ranges = {
    "us-east-2"      = "52.15.247.160/27"
    "us-east-1"      = "52.23.63.224/27"
    "us-west-2"      = "54.70.204.128/27"
    "af-south-1"     = "13.246.220.192/27"
    "ap-southeast-3" = "43.218.71.192/27"
    "ap-southeast-5" = "56.68.33.0/27"
    "ap-south-1"     = "52.66.193.64/27"
    "ap-northeast-2" = "13.124.145.32/27"
    "ap-southeast-1" = "13.229.254.0/27"
    "ap-southeast-2" = "54.153.249.96/27"
    "ap-northeast-1" = "13.113.244.32/27"
    "ca-central-1"   = "15.223.73.0/27"
    "cn-north-1"     = "71.136.65.64/27"
    "eu-central-1"   = "35.158.127.192/27"
    "eu-west-1"      = "52.210.255.224/27"
    "eu-west-2"      = "35.177.218.0/27"
    "eu-south-1"     = "18.102.150.128/27"
    "eu-west-3"      = "13.38.202.0/27"
    "eu-south-2"     = "18.101.99.160/27"
    "eu-north-1"     = "13.53.191.64/27"
    "eu-central-2"   = "16.63.53.32/27"
    "sa-east-1"      = "18.230.46.192/27"
    "us-gov-east-1"  = "18.252.165.64/27"
    "us-gov-west-1"  = "160.1.180.32/27"
    "il-central-1"   = "51.17.195.32/27"
    "me-central-1"   = "51.112.11.224/27"
  }

  quicksight_cidr = coalesce(
    var.quicksight_ip_override != "" ? var.quicksight_ip_override : null,
    lookup(local.quicksight_ip_ranges, var.aws_region, null),
  )
}
