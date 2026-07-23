# Context: QuickSight vs Metabase AI Capabilities Comparison

## Goal
Comparing Amazon QuickSight (now rebranded "Amazon Quick Suite" / "Amazon Quick") and
Metabase on their AI capabilities, using a shared sample dataset for hands-on testing.
Have a local Metabase stack already running against the Metabase QA sample Postgres DB.
Want to stand up the *same* sample DB on AWS so QuickSight can connect to it, then build
out the semantic-layer/AI features in both tools side by side.

## Comparison framework (already researched, use as the report skeleton)
1. Short list of known features (per product)
2. Where AI is available today (in-product / API / MCP)
3. Whether the same AI capabilities are consistent across those surfaces
4. How extensible each is (embedding, custom models, governance controls)

Deeper questions to answer along the way:
- How do users diagnose/correct wrong AI answers without vendor help?
- How does the AI stay aligned with governed metrics/business definitions?
- Who can modify AI behavior, and how?
- What context sources does the AI draw on to understand the data/business?
- How does it integrate with existing data ecosystems/governance?
- How do users improve AI performance post-deployment, and who can do it?
- What workflows exist for monitoring quality and catching failures over time?

## Key research findings so far
- **QuickSight rebrand**: QuickSight was renamed Amazon Quick Suite (Oct 9, 2025), then
  further shortened to "Amazon Quick" in some UI/docs. Same underlying BI engine (SPICE),
  new AI layer bundled in (Quick chat, Quick Research, Quick Flows, Quick Automate, Quick
  Index). Expect inconsistent naming across docs/screenshots depending on age.
- **QuickSight AI**: NLQ/Q&A via "Topics" (a semantic layer you configure with synonyms,
  friendly names, named filters, semantic types), Generative BI dashboard authoring,
  natural-language calculated fields, executive summaries, "Generate Analysis"/data
  stories. Powered by Amazon Bedrock LLMs. MCP support exists but mainly in the
  *client* direction (Quick agents calling out to external MCP tools, e.g. New Relic),
  not clearly as an MCP server other agents connect to.
- **Metabase AI**: Metabot (chat assistant — NLQ, SQL generation, error fixing, chart/
  dashboard summaries), an official MCP **server** (Metabase can be connected to from
  Claude or other AI clients), an Agent API, AI governance features added in v61
  (per-group access controls, token/message limits, custom system prompts, usage
  analytics), bring-your-own-model support (Anthropic supported now, more providers
  coming per v63 — OpenAI, Bedrock, Azure).
- **Key architectural contrast to highlight in the report**: Metabase positions itself as
  something your AI stack plugs *into* (MCP server); QuickSight/Quick positions itself as
  an agent that plugs *into* other systems (MCP client). Worth digging into further.
- Flagged as "needs deeper verification": exact API parity for QuickSight's generative
  authoring features outside the console/embedded SDK; live pricing/tier gating for AI
  features on both sides.

## Sample dataset details (metabase/qa-databases:postgres-sample-15)
- Docker image: `metabase/qa-databases:postgres-sample-15`
- Contains the classic "Metabase Sample Database" — People / Products / Orders / Reviews
  e-commerce dataset
- Standard credentials baked into the image: database `sample`, user `metabase`,
  password `metasample123`
- Already running locally for the Metabase side of the comparison

## AWS setup (done — see infra/postgres-sample-db/)
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
- Outputs: public IP, ready to paste into QuickSight's "New dataset → PostgreSQL"
  connection form (Server = public IP, Port 5432, Database `sample`, user/pass as above)
- Clean `terraform destroy` path so the box isn't left running/billing between sessions
- Terraform was written and HCL-syntax-checked in the Cowork sandbox, but **not** run —
  no AWS credentials or working `terraform`/`aws` CLI available there. Needs `terraform
  init && terraform plan && terraform apply` run locally by you.

## Semantic-layer objects to build once the DB is connected (for testing the AI tools)
**QuickSight:**
- Dataset(s) from the `sample` tables, imported to SPICE
- Calculated fields (e.g. profit margin, order-to-ship days)
- A Topic with friendly names/synonyms mapped onto fields (this is QuickSight's semantic
  layer for NLQ — e.g. "revenue" → TOTAL, "customer" → PEOPLE.NAME)
- Named filters, default date field, semantic type overrides in the Topic
- A dashboard for Executive Summaries / Generate Analysis / data stories
- Optional: row-level security to test whether AI answers respect it

**Metabase:**
- Database connection to `sample` (either existing local instance, or a second connection
  pointed at the new AWS-hosted copy for a literal shared instance)
- A Model (curated/renamed table or join) — Metabase's semantic-layer equivalent to a
  QuickSight Topic
- A Metric (e.g. governed "Total Revenue" definition)
- A couple of Verified Questions/dashboards
- Metabot enabled with an AI provider key (have an Anthropic key available)
- The official Metabase MCP server running, pointed at this instance, for testing the
  MCP-client (Claude → Metabase) direction directly

## Immediate next step
Run the Terraform in `infra/postgres-sample-db/` to stand up the EC2 box, then move on to
building the QuickSight Topic and Metabase Model/Metric definitions for this specific
schema.

## Deliverable
Working folder with: Terraform code for the AWS Postgres sandbox (done), a README
tracking setup steps and findings, and eventually a written comparison report following
the 4-part framework above.
