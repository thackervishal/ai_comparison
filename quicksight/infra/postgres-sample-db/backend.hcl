# Copy to backend.hcl and fill in the bucket name from:
#   cd ../state-bootstrap && terraform output bucket_name
#
# backend.hcl itself SHOULD be committed to git (unlike terraform.tfvars) --
# it's just the shared bucket coordinates, not per-developer secrets. Every
# developer runs `terraform init -backend-config=backend.hcl` against the
# same file so everyone's plan/apply reads and writes the same state.

bucket       = "qs-mb-tfstate-388096319864"
key          = "postgres-sample-db/terraform.tfstate"
region       = "us-east-1"
use_lockfile = true
encrypt      = true
