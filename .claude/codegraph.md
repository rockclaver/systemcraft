# Code Graph
> Commit: 487d3a6 | Date: 2026-04-07 | Files: 16 | Lang: markdown + scripts

## Architecture Overview
SystemCraft is a catalog of reusable AI agent skills. Each skill is a self-contained folder under `skills/` containing a `SKILL.md` (frontmatter + instructions), an optional `REFERENCE.md` (extended docs), and optional `scripts/` (deterministic helpers). Skills are discovered by matching the `description` frontmatter against user prompts.

## Module Index

### skills/

| File | Purpose | Key Exports | Used by |
|---|---|---|---|
| `code-graph/SKILL.md` | Builds and maintains a `.claude/codegraph.md` codebase index so the agent can navigate a repo from one file instead of scanning many. | skill: `code-graph` | — |
| `code-graph/REFERENCE.md` | Documents the codegraph file format, node template, folder-level summary format, and token budget rules. | — | `code-graph/SKILL.md` |
| `code-graph/scripts/scan.js` | CLI script that discovers files, extracts exports/imports via grep, and emits a structured draft codegraph. | — | `code-graph/SKILL.md` |
| `design-api/SKILL.md` | Designs and implements consistent REST API endpoints (handlers, routing, validation, error responses) with full test coverage. | skill: `design-api` | — |
| `design-api/REFERENCE.md` | Canonical patterns for DRY API design: shared utilities, error shapes, validation conventions, and endpoint templates. | — | `design-api/SKILL.md` |
| `dockerize-and-deploy/SKILL.md` | Produces production-grade Dockerfiles, docker-compose setup with volumes, and a pre-flight validation script for a given repo. | skill: `dockerize-and-deploy` | — |
| `dockerize-and-deploy/REFERENCE.md` | Deployment patterns, volume configuration examples, and validation script templates. | — | `dockerize-and-deploy/SKILL.md` |
| `find-code/SKILL.md` | Locate files and code precisely with grep and shell tools instead of AI guessing. | skill: `find-code` | — |
| `grill-me/SKILL.md` | Conducts a relentless Socratic interview to stress-test a plan or design until all decision branches are resolved. | skill: `grill-me` | — |
| `migrate-to-better-auth/SKILL.md` | Detects any existing auth system and produces a phased migration plan to better-auth, rewriting config, routes, and seed data. | skill: `migrate-to-better-auth` | — |
| `migrate-to-better-auth/REFERENCE.md` | Provider-specific migration notes, better-auth plugin options, and common pitfall patterns. | — | `migrate-to-better-auth/SKILL.md` |
| `prd-to-plan/SKILL.md` | Converts a PRD into a multi-phase tracer-bullet implementation plan saved to `./plans/`. | skill: `prd-to-plan` | — |
| `refactor-codebase/SKILL.md` | Incrementally refactors a codebase toward a scalable structure using a phased plan without breaking the working system. | skill: `refactor-codebase` | — |
| `request-refactor-plan/SKILL.md` | Create a detailed refactor plan with tiny commits via user interview, then file it as a GitHub issue. | skill: `request-refactor-plan` | — |
| `server-access/SKILL.md` | Resolve a named server from credentials, connect over SSH, and run remote checks or inspection commands. | skill: `server-access` | — |
| `tdd/SKILL.md` | Provides test-driven development guidance, emphasizing interface design, mocking, and incremental refactoring. | skill: `tdd` | — |
| `triage-issue/SKILL.md` | Triages GitHub issues by clarifying requirements, exploring the codebase, and proposing a fix strategy. | skill: `triage-issue` | — |
| `write-a-prd/SKILL.md` | Guides the agent through user interviews and codebase exploration to produce a PRD, then submits it as a GitHub issue. | skill: `write-a-prd` | — |
| `write-a-skill/SKILL.md` | Guides the agent in creating new skills with proper frontmatter, progressive disclosure, and bundled resources. | skill: `write-a-skill` | — |
| `write-feature-prd/SKILL.md` | Write feature PRDs grounded in the current codebase, reusable modules, and available tools. | skill: `write-feature-prd` | — |
| `write-tests/SKILL.md` | Writes high-value automated tests by inspecting the repo, inferring the test stack, and targeting risky untested behavior first. | skill: `write-tests` | — |

## Config & Schema Files

- `README.md` — project overview, skill authoring guidelines, installation instructions, and discovery/troubleshooting guide

---
_Regenerate: `node <skill-dir>/scripts/scan.js > .claude/codegraph.draft.md`_
