# QuickSight vs Metabase Comparison — Infra & Session Log

This file tracks *setup/infra history* only — what's been installed, deployed, and how
to pick this up on another machine. The comparison framework, research findings on
QuickSight/Metabase AI capabilities, and the semantic-layer build plan live in
`quicksight/RESEARCH.md` instead, kept separate so this file (auto-loaded every session)
stays small.

## Sample dataset details (metabase/qa-databases:postgres-sample-15)
- Docker image: `metabase/qa-databases:postgres-sample-15`
- Contains the classic "Metabase Sample Database" — People / Products / Orders / Reviews
  e-commerce dataset
- Standard credentials baked into the image: database `sample`, user `metabase`,
  password `metasample123`
- Already running locally for the Metabase side of the comparison

## AWS setup — DEPLOYED (2026-07-22, see quicksight/infra/postgres-sample-db/)
Terraform stands up a small EC2 instance running this same Docker image so QuickSight
(a SaaS product with no "localhost" connector) can reach it.
- `aws_instance`: Amazon Linux 2023, t3.micro, with `user_data` to install Docker and run
  `docker run -d --restart unless-stopped -p 5432:5432 metabase/qa-databases:postgres-sample-15`
- `aws_security_group`: ingress on 5432 for (a) your own IP for `psql`/local Metabase
  testing, and (b) QuickSight's IP range for the target region. Note: the
  `aws_ip_ranges` data source does **not** have a `quicksight` service value (checked
  ip-ranges.json directly) — QuickSight's ranges are only published as a static table at
  https://docs.aws.amazon.com/quicksight/latest/user/regions.html, so that table is
  hardcoded into `quicksight_ip_ranges.tf` instead, with an override variable.
- Outputs: public IP, ready to paste into QuickSight's "New data source → PostgreSQL"
  connection form (Server = public IP, Port 5432, Database `sample`, user/pass as above),
  then build a dataset from a table/query on top of that data source.
- Clean `terraform destroy` path so the box isn't left running/billing between sessions.
- Full connection details and the current resource ID table live in
  `quicksight/infra/postgres-sample-db/README.md` under "Currently Deployed Resources".

### What actually happened this session
- Neither `terraform` nor the `aws` CLI were installed locally — installed both (apt repo
  for Terraform, AWS's official installer for the CLI). Auth was via `aws login` (CLI v2's
  browser-based flow that reuses an existing AWS Console session — no access keys needed).
- Ran `state-bootstrap` first (creates the S3 bucket the main config uses as its remote
  backend) → bucket `qs-mb-tfstate-388096319864`. Wired that into
  `quicksight/infra/postgres-sample-db/backend.hcl` (copied from the `.example`,
  committed — it's just bucket coordinates, not a secret).
- Filled `quicksight/infra/postgres-sample-db/terraform.tfvars` (gitignored) with the
  real public IP.
- First `terraform apply` on the main config **failed**: `t3.micro` isn't offered in
  `us-east-1e`, and `vpc.tf` picked a subnet with `data.aws_subnets.default.ids[0]`
  blindly, landing on that AZ. Fixed by adding a
  `data.aws_ec2_instance_type_offerings` lookup in `vpc.tf` and filtering the subnet
  query to only AZs that actually support `var.instance_type` — general fix, not
  hardcoded to `us-east-1e`, so it holds if the account/region/instance type changes.
  Re-ran `apply` and it succeeded.
- Full "currently deployed resources" table (bucket, security group, instance ID, subnet,
  public IP at creation) plus manual-teardown-without-Terraform steps are now recorded in
  `quicksight/infra/postgres-sample-db/README.md` under "Currently Deployed Resources" —
  check there (or `terraform output`/`terraform state list`) for current values, since
  public IP and instance ID change on stop/start or destroy/recreate.
- Confirmed: you can reach the DB directly from your laptop with
  `psql "postgresql://metabase:metasample123@<public_ip>:5432/sample"` since your IP is
  in the security group. QuickSight itself is a separate SaaS subscription Terraform
  doesn't create — signed up (Standard edition, `us-east-1`), created the PostgreSQL data
  source successfully.

## Immediate next step
EC2 box is up and reachable, QuickSight data source is created. Next: build the actual
dataset(s) and Topic — see `quicksight/RESEARCH.md` for the semantic-layer build plan
(the dataset/Topic join-key finding recorded there matters for how this gets built) and
the open research questions for the comparison report.
