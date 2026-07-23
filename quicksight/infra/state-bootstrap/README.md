# State bootstrap

Creates the S3 bucket used as remote state storage for `../postgres-sample-db`.
Run this once, by anyone with AWS admin creds -- it doesn't need to be repeated
per developer.

```bash
cd state-bootstrap
terraform init
terraform apply
terraform output bucket_name
```

Take that bucket name and put it in `../postgres-sample-db/backend.hcl`
(copy from `backend.hcl.example`). See the main README's "Remote state"
section for the full flow.

This module's state is local on purpose -- it's a handful of resources that
essentially never change after the first apply, so there's no real
collaboration benefit to putting it in S3 too (and it'd have the same
chicken-and-egg problem this bucket exists to solve). If you do want it
remote later, migrate it the same way as any other config.

If whoever ran this loses their local state (laptop wiped, etc.) and someone
re-runs `apply`, bucket creation will fail with `BucketAlreadyExists` since
the bucket still exists in AWS. Fix: `terraform import aws_s3_bucket.state
<bucket-name>` (plus the versioning/encryption/public-access-block
resources, same pattern) to reattach state to the real bucket, rather than
trying to create a second one.
