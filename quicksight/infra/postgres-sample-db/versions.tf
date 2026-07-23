terraform {
  required_version = ">= 1.11.0" # needed for native S3 state locking (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Bucket/key/region intentionally left out here -- they're supplied via
  # `terraform init -backend-config=backend.hcl` so every developer points
  # at the same shared bucket without hardcoding it into version-controlled
  # .tf files in a way that's awkward to change later. See backend.hcl.example
  # and the README's "Remote state" section.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
