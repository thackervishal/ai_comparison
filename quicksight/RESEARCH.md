# QuickSight vs Metabase — AI Capabilities Research & Analysis

Analysis, findings, and the build plan for the comparison report. Infra setup
history and current deployment status live in the root `CLAUDE.md` instead —
this file is not auto-loaded into every session, so open it explicitly when
working on the actual comparison content.

## Goal
Comparing Amazon QuickSight (now rebranded "Amazon Quick Suite" / "Amazon Quick") and
Metabase on their AI capabilities, using a shared sample dataset for hands-on testing.
Have a local Metabase stack already running against the Metabase QA sample Postgres DB.
Stood up the *same* sample DB on AWS so QuickSight can connect to it, then build out the
semantic-layer/AI features in both tools side by side.

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

## Key finding: QuickSight datasets/Topics don't auto-detect FKs (2026-07-22)
A "dataset" isn't strictly single-table — the dataset editor lets you drag in multiple
tables and manually define join clauses to build one denormalized dataset. But
**QuickSight never reads Postgres's actual FK constraints**; there's no auto-introspection
that turns `orders.customer_id -> people.id` into a suggested join. You always manually
pick tables + manually specify join keys. Topic is a separate, higher layer (NLQ/semantic:
friendly names, synonyms, calculated fields) that sits on top of already-built dataset(s);
newer QuickSight versions also let a Topic reference multiple datasets and define
relationships *between* them at the Topic level (a second, separate place joins can be
specified, used only for Q&A). Either path — one big joined dataset, or several
single-table datasets with Topic-level relationships — requires manually re-entering the
FKs that already exist in the schema. Worth contrasting with Metabase, which auto-detects
FKs from its schema sync and exposes them as ready-made joins in the query builder/Models
without manual re-entry — a concrete data point for "what context sources does the AI draw
on to understand the data" in the comparison report.

## Semantic-layer objects to build once the DB is connected (for testing the AI tools)
**QuickSight:**
- Dataset(s) from the `sample` tables, imported to SPICE — either one dataset joining
  People/Orders/Products/Reviews via manually-specified join keys, or four single-table
  datasets with relationships defined inside the Topic (see finding above)
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

## QuickSight/Quick Suite concepts to experiment with
Glossary-in-progress, filled in as each object gets tested. One entry per QuickSight
building block — data source and dataset are confirmed/tested; the rest are still to try.

- **Data source** — the connection itself (server/port/db/creds). Tested: created a
  PostgreSQL data source pointed at the EC2 box.
- **Dataset** — a table-shaped thing built from a data source: either (a) a single raw
  table, or (b) a custom SQL query. **Finding**: don't use a join-across-tables SQL query
  as the dataset definition — a 1-to-many join (e.g. People ⋈ Orders ⋈ Reviews) explodes
  row volume (each parent row repeats once per child row), which corrupts aggregates
  computed on the flattened result. **Decision**: create one dataset per table instead
  (no joins at the dataset level), and push join logic up to the Topic layer.
- **Topic** — the semantic/NLQ layer; this is where dataset-to-dataset relationships
  (joins) actually belong, given the dataset-level SQL-join problem above. Not yet
  tested. **Finding**: Topics are not usable by Apps (see below) — so the join
  definitions living in a Topic don't carry over if the app-building surface is where
  you want the joined schema.
- **Spaces** — not yet tested.
- **Research** ("Quick Research") — not yet tested.
- **Chat agent** ("Quick chat") — not yet tested.
- **Apps** ("Quick Apps") — generates a web app, written in TypeScript, with a chat-like
  interface. **Finding**: an App can access **datasets** but *cannot* access data sources
  or Topics directly — meaning any join/relationship logic defined at the Topic level is
  invisible to an App; it only ever sees the raw per-table (or per-query) datasets. This
  is a real constraint on how far the "semantic layer" actually reaches across surfaces —
  relevant to the report's "is AI consistent across surfaces" question.
- **Flows** ("Quick Automate"/Flows) — not yet tested.
- **Analyses** — the traditional dashboard-authoring surface (visuals on top of
  dataset(s)); not yet tested in this pass but is the classic QuickSight object
  Generative BI/Executive Summaries build on top of.

## Deliverable
Working folder with: Terraform code for the AWS Postgres sandbox (done), a README
tracking setup steps and findings, and eventually a written comparison report following
the 4-part framework above.
