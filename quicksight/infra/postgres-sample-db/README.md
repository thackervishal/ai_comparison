# Postgres sample DB for the QuickSight vs Metabase comparison

Stands up a single small EC2 instance that runs
`metabase/qa-databases:postgres-sample-15` directly (via Docker), so
QuickSight — a SaaS product with no "localhost" connector — can reach the
*exact same* Postgres your local Metabase QA stack already uses. Same image,
same data, same credentials, just reachable over the internet instead of
`localhost`.

| | |
|---|---|
| DB name | `sample` |
| Username | `metabase` |
| Password | `metasample123` (baked into the image) |
| Port | `5432` |

## Why EC2 + Docker, not RDS

An earlier version of this config used RDS with a script to re-load the
sample data from a SQL dump. That was a mistake — RDS can't run an arbitrary
Docker image, so it meant hosting a Postgres that merely *contained the same
data* rather than running the actual QA image, and it needed a whole
separate data-loading step. This version runs the image itself
(`docker run ... metabase/qa-databases:postgres-sample-15`) on a plain EC2
box via `user_data`, which is simpler and matches what the image is for —
identical Postgres on both sides of the comparison, no data-loading step
needed.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.11 (needed for native S3 state locking)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- AWS credentials for an account everyone touching this is allowed to spend money in

This sandbox environment has neither AWS credentials nor a working
`terraform` binary (couldn't reach `releases.hashicorp.com` to install it),
so I couldn't run `terraform apply`, `validate`, or `fmt` for you — you'll
need to run this yourself. I did check every `.tf` file parses as valid HCL,
but that's not a substitute for `terraform init && terraform validate`,
which you should run first.

## Configuring your AWS credentials

Everyone running this currently has personal admin credentials, so the
simplest setup is:

```bash
aws configure
# or, if your org uses SSO: aws configure sso
```

Then verify Terraform can see them:

```bash
aws sts get-caller-identity
```

That's it — Terraform (and the AWS CLI) automatically pick up whatever
credentials are active for your shell (env vars, a named profile via
`AWS_PROFILE`, or SSO). No credentials are stored in this repo or in
Terraform state.

Worth flagging even though it's out of scope to fix right now: everyone
using personal admin creds to run `plan`/`apply` means anyone can change or
delete anything in the account, and state won't show *who* ran what. Fine
for a small team standing up a throwaway comparison box; something to
revisit (scoped IAM role, CI-driven applies) if this sticks around or the
account holds anything more sensitive.

## Remote state (one-time setup, shared across the team)

State lives in S3, not on anyone's laptop, so multiple people can run
`plan`/`apply` against the same infrastructure without stepping on each
other. Locking uses S3's native conditional-write locking
(`use_lockfile = true`) — no DynamoDB table needed.

**First time only** — someone runs the bootstrap module to create the state bucket:

```bash
cd state-bootstrap
terraform init
terraform apply
terraform output bucket_name
```

Take that bucket name and put it in `postgres-sample-db/backend.hcl`:

```bash
cd ../postgres-sample-db
cp backend.hcl.example backend.hcl
# edit backend.hcl, paste the bucket name in
```

`backend.hcl` is **not** a secret (it's just bucket/key/region) — commit it,
so everyone else just does:

```bash
git pull
terraform init -backend-config=backend.hcl
```

and lands on the same shared state automatically. (If you already ran
`terraform init` before this backend existed, run
`terraform init -backend-config=backend.hcl -migrate-state` instead, to move
existing local state into S3 rather than starting fresh.)

## Setup

```bash
cd postgres-sample-db
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`: set `my_ip_cidr` to your own public IP as a `/32`
(`curl -s ifconfig.me`). That's the only required change. The QuickSight IP
range for `aws_region` is looked up automatically — see
`quicksight_ip_ranges.tf` for where that comes from and why it's a static
table rather than a Terraform data source.

```bash
terraform plan
terraform apply
```

(`terraform init -backend-config=backend.hcl` from the previous section
needs to have been run first.)

This creates, in your account's default VPC:
- A security group open to: your IP (Postgres + optionally SSH), and QuickSight's published IP range for `aws_region` (Postgres only)
- A `t3.micro` EC2 instance (Amazon Linux 2023, free-tier eligible) that installs Docker via `user_data` and runs `docker run -d --restart unless-stopped -p 5432:5432 metabase/qa-databases:postgres-sample-15`

Docker pull + container start typically finishes within a minute or two of
the instance boot. If `psql` can't connect right away, give it a moment,
then check `terraform output ssh_command` to SSH in and run
`docker logs qa-postgres` if it's still not up.

## A note on the QuickSight IP range

AWS does **not** expose QuickSight's outbound IP range through the
`aws_ip_ranges` Terraform data source — I checked `ip-ranges.json` directly
and there's no `QUICKSIGHT` service value in it (only things like `AMAZON`,
`EC2`, `S3`). QuickSight instead publishes a single static `/27` per region
on a docs page:
[AWS Regions, websites, IP address ranges, and endpoints](https://docs.aws.amazon.com/quicksight/latest/user/regions.html).
`quicksight_ip_ranges.tf` hardcodes that table (captured 2026-07-22) with a
`quicksight_ip_override` variable in case it's changed by the time you run
this or your region isn't listed.

## Cost

`t3.micro` is free-tier eligible; outside free tier it's roughly
**$7-8/month** in `us-east-1` if left running continuously (check the
[EC2 pricing page](https://aws.amazon.com/ec2/pricing/on-demand/) for
current rates), plus a couple cents for the 10GB gp3 volume. Since this is
just for a side-by-side comparison:

```bash
terraform destroy
```

and re-`apply` next time — the whole thing (instance boot + Docker pull) takes a couple of minutes.

## Currently Deployed Resources

Point-in-time record from the first `apply` (account `388096319864`,
`us-east-1`, 2026-07-22) — for manual cleanup via the AWS console/CLI if
Terraform state is ever unavailable. `terraform state list` / `terraform
show` in each directory is the actual source of truth. The public IP and
instance ID change on every destroy/recreate, and the public IP also changes
on stop/start, so re-check with `terraform output` before trusting this
table if it's been a while.

| Resource | Module | Identifier |
| --- | --- | --- |
| S3 state bucket | `state-bootstrap` | `qs-mb-tfstate-388096319864` |
| Security group | `postgres-sample-db` | `sg-08639fa4c68a5dd04` (`qs-mb-sample-db-sg`) |
| EC2 instance | `postgres-sample-db` | `i-03179ab1d45ae31e5` (`qs-mb-sample-db`) |
| Subnet used | `postgres-sample-db` | `subnet-057bd08c94e6d4869` |
| Public IP (at creation) | `postgres-sample-db` | `54.226.220.95` |

Connection details (re-derive host from `terraform output public_ip` if it's
since changed — the rest is fixed, baked into the Docker image):

| Field | Value |
| --- | --- |
| Host | `54.226.220.95` |
| Port | `5432` |
| Database | `sample` |
| Username | `metabase` |
| Password | `metasample123` |

Full connection string, same info assembled together:

```text
postgresql://metabase:metasample123@54.226.220.95:5432/sample
```

To tear everything down manually (in reverse order of creation, only if
`terraform destroy` isn't available):

1. Terminate the EC2 instance.
2. Delete the security group (after the instance is gone).
3. Empty and delete the S3 bucket (versioned, so delete all object versions
   first: `aws s3api delete-objects` or the console's "empty bucket" action).

## Connecting Metabase

Add a second Postgres data source in Metabase pointed at `terraform output
public_ip`, port 5432, db `sample`, same credentials as your existing local
connection — useful if you want both sides of the comparison hitting the
literal same running instance rather than two copies of the same data.

## Connecting QuickSight

QuickSight → Datasets → New dataset → PostgreSQL, which first creates a data
source (the connection):
- Server: `terraform output public_ip`
- Port: 5432
- Database: `sample`
- Username / Password: `metabase` / `metasample123`

Then pick a table (or write a custom SQL query) to create the dataset itself
from that data source.

## Files

```
infra/
├── state-bootstrap/         # run once: creates the S3 state bucket
│   ├── main.tf
│   └── README.md
└── postgres-sample-db/
    ├── versions.tf              # terraform + aws provider version pins, backend "s3" {}
    ├── variables.tf             # all inputs, with sane defaults
    ├── vpc.tf                   # looks up the default VPC/subnet
    ├── quicksight_ip_ranges.tf  # static per-region QuickSight CIDR table
    ├── security_group.tf        # port 5432 (+ optional 22) ingress
    ├── main.tf                  # the EC2 instance + Docker user_data
    ├── outputs.tf                # public IP / connection info
    ├── terraform.tfvars.example # copy to terraform.tfvars and edit (per-developer, gitignored)
    ├── backend.hcl.example      # copy to backend.hcl and edit (shared, committed)
    └── README.md
```
